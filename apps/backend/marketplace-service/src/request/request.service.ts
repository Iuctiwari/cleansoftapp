import { randomUUID } from 'node:crypto';

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { hasPermission, Permissions } from '@nexoraa/shared';
import type { FilterQuery, UpdateQuery } from 'mongoose';

import { AddressService } from '../address/address.service';
import { distanceMeters, fromGeoJson, roundKm, toGeoJson } from '../platform/geo';
import {
  MarketplaceDatabase,
  type RequestHistoryEntry,
  type RequestStatus,
  type ServiceRequestDocument,
  type ShopListingDocument,
} from '../platform/marketplace.database';
import {
  CATEGORY_LABELS,
  type ConsumerPrincipal,
  type ServiceMode,
  type ShopPrincipal,
} from '../platform/marketplace.types';
import { ShopServicesClient } from '../platform/shop-services.client';
import { TenantDirectoryClient } from '../platform/tenant-directory.client';
import type {
  AcceptRequestDto,
  CancelRequestDto,
  CompleteRequestDto,
  CreateServiceRequestDto,
  DeclineRequestDto,
  LinkOrderDto,
  ListRequestsQueryDto,
} from './request.dto';

/** A shop has this long to answer before the request expires. */
export const REQUEST_EXPIRY_HOURS = 48;
/** How far ahead a customer can ask for a date. */
export const MAX_DAYS_AHEAD = 30;
export const MAX_PENDING_PER_SHOP = 3;
export const MAX_PENDING_TOTAL = 10;

const TRAVELLING_MODES: readonly ServiceMode[] = ['home_service', 'pickup_drop'];
const IST_OFFSET_MS = 330 * 60_000;

/** Today's date in India as YYYY-MM-DD. */
export function istToday(now: Date): string {
  return new Date(now.getTime() + IST_OFFSET_MS).toISOString().slice(0, 10);
}

function addDays(date: string, days: number): string {
  const value = new Date(`${date}T00:00:00Z`);
  value.setUTCDate(value.getUTCDate() + days);
  return value.toISOString().slice(0, 10);
}

function isRealDate(date: string): boolean {
  const value = new Date(`${date}T00:00:00Z`);
  return !Number.isNaN(value.getTime()) && value.toISOString().slice(0, 10) === date;
}

/** "2026-10-08" + "10:30" (India time) → ISO instant. */
export function istInstant(date: string, clock: string): string {
  return new Date(`${date}T${clock}:00+05:30`).toISOString();
}

export interface PageOf<T> {
  readonly items: readonly T[];
  readonly page: number;
  readonly limit: number;
  readonly total: number;
}

export interface CustomerRequestView {
  readonly requestId: string;
  readonly requestNumber: string;
  readonly shop: {
    readonly shopId: string;
    readonly shopName: string;
    readonly branchName: string;
    readonly phone: string;
  };
  readonly category: string;
  readonly categoryLabel: string;
  readonly requestType: ServiceMode;
  readonly description: string;
  readonly items: ServiceRequestDocument['items'];
  readonly preferredDate: string;
  readonly preferredSlot: ServiceRequestDocument['preferredSlot'];
  readonly address?: { readonly label: string; readonly formatted: string };
  readonly status: RequestStatus;
  readonly confirmedAt?: string;
  readonly shopNote?: string;
  readonly declineReason?: string;
  readonly cancelReason?: string;
  readonly orderNumber?: string;
  /** While Pending: when the request expires if the shop does not answer. */
  readonly expiresAt?: string;
  readonly canCancel: boolean;
  readonly history: readonly Omit<RequestHistoryEntry, 'actorId'>[];
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface ShopRequestView
  extends Omit<CustomerRequestView, 'address' | 'history' | 'canCancel'> {
  readonly customer: ServiceRequestDocument['customer'];
  /** The customer's record on this branch's customer list. */
  readonly shopCustomerId?: string;
  readonly address?: {
    readonly label: string;
    readonly formatted: string;
    readonly landmark?: string;
    readonly contactName: string;
    readonly contactPhone: string;
    readonly latitude: number;
    readonly longitude: number;
  };
  readonly distanceKm?: number;
  readonly orderId?: string;
  readonly actions: {
    readonly accept: boolean;
    readonly decline: boolean;
    readonly linkOrder: boolean;
    readonly complete: boolean;
  };
  readonly history: readonly RequestHistoryEntry[];
}

export interface ShopRequestSummary {
  readonly pending: number;
  readonly accepted: number;
  readonly completed: number;
  readonly declined: number;
  readonly cancelled: number;
  readonly expired: number;
}

@Injectable()
export class RequestService {
  constructor(
    private readonly database: MarketplaceDatabase,
    private readonly addressService: AddressService,
    private readonly tenantDirectory: TenantDirectoryClient,
    private readonly shopServices: ShopServicesClient,
  ) {}

  // ── Customer side ─────────────────────────────────────────────────────────

  async create(
    consumer: ConsumerPrincipal,
    input: CreateServiceRequestDto,
  ): Promise<CustomerRequestView> {
    const listing = await this.findBookableShop(input.shopId);
    const now = new Date();

    if (!listing.categories.includes(input.category)) {
      throw new BadRequestException(
        `${listing.shopName} does not offer ${CATEGORY_LABELS[input.category]}`,
      );
    }
    if (!listing.serviceModes.includes(input.requestType)) {
      throw new BadRequestException('This shop does not offer that kind of service');
    }
    this.assertDateAndSlot(listing, input, now);

    const travelling = TRAVELLING_MODES.includes(input.requestType);
    let address: ServiceRequestDocument['address'];
    let distanceKm: number | undefined;
    if (travelling || input.addressId) {
      if (!input.addressId) {
        throw new BadRequestException('Choose the address for home service or pickup');
      }
      const saved = await this.addressService.resolve(consumer.consumerId, input.addressId);
      const meters = distanceMeters(
        { latitude: saved.latitude, longitude: saved.longitude },
        fromGeoJson(listing.location!),
      );
      if (travelling && meters > listing.serviceRadiusKm * 1000) {
        throw new BadRequestException(
          `This shop serves up to ${listing.serviceRadiusKm} km away; your address is ${roundKm(meters)} km away`,
        );
      }
      distanceKm = roundKm(meters);
      address = {
        addressId: saved.addressId,
        label: saved.label,
        contactName: saved.contactName,
        contactPhone: saved.contactPhone,
        formatted: saved.formatted,
        ...(saved.landmark ? { landmark: saved.landmark } : {}),
        location: toGeoJson({ latitude: saved.latitude, longitude: saved.longitude }),
      };
    }

    await this.expireDue({ consumerId: consumer.consumerId });
    const [pendingHere, pendingTotal] = await Promise.all([
      this.database.requests.countDocuments({
        consumerId: consumer.consumerId,
        branchId: listing.branchId,
        status: 'Pending',
      }),
      this.database.requests.countDocuments({ consumerId: consumer.consumerId, status: 'Pending' }),
    ]);
    if (pendingHere >= MAX_PENDING_PER_SHOP) {
      throw new ConflictException(
        `You already have ${MAX_PENDING_PER_SHOP} requests waiting at this shop`,
      );
    }
    if (pendingTotal >= MAX_PENDING_TOTAL) {
      throw new ConflictException(`You already have ${MAX_PENDING_TOTAL} requests waiting`);
    }

    // The customer joins the branch's customer list as soon as they send a request.
    const shopCustomerId = await this.shopServices.linkOnlineCustomer(
      listing.tenantId,
      listing.branchId,
      {
        consumerId: consumer.consumerId,
        name: consumer.displayName,
        mobile: consumer.mobileNumber,
        email: consumer.email || undefined,
        address: address?.formatted,
      },
    );

    const year = istToday(now).slice(0, 4);
    const sequence = await this.database.nextSequence(`serviceRequest-${year}`);
    const createdAt = now.toISOString();
    const request: ServiceRequestDocument = {
      requestId: randomUUID(),
      requestNumber: `SR-${year}-${String(sequence).padStart(6, '0')}`,
      consumerId: consumer.consumerId,
      customer: {
        name: consumer.displayName,
        mobile: consumer.mobileNumber,
        email: consumer.email,
      },
      tenantId: listing.tenantId,
      branchId: listing.branchId,
      shop: {
        shopName: listing.shopName,
        branchName: listing.branchName,
        phone: listing.bookingPhone || listing.ownerPhone,
      },
      category: input.category,
      requestType: input.requestType,
      description: input.description.trim(),
      items: (input.items ?? []).map((item) => ({
        name: item.name.trim(),
        quantity: item.quantity,
      })),
      preferredDate: input.preferredDate,
      preferredSlot: input.preferredSlot,
      ...(address ? { address } : {}),
      ...(distanceKm !== undefined ? { distanceKm } : {}),
      status: 'Pending',
      ...(shopCustomerId ? { shopCustomerId } : {}),
      expiresAt: new Date(now.getTime() + REQUEST_EXPIRY_HOURS * 3_600_000).toISOString(),
      statusHistory: [
        { status: 'Pending', at: createdAt, by: 'customer', actorId: consumer.consumerId },
      ],
      createdAt,
      updatedAt: createdAt,
    };
    await this.database.requests.create(request);
    return this.toCustomerView(request);
  }

  async listForCustomer(
    consumer: ConsumerPrincipal,
    query: ListRequestsQueryDto,
  ): Promise<PageOf<CustomerRequestView>> {
    await this.expireDue({ consumerId: consumer.consumerId });
    const page = await this.page({ consumerId: consumer.consumerId }, query);
    return { ...page, items: page.items.map((request) => this.toCustomerView(request)) };
  }

  async getForCustomer(
    consumer: ConsumerPrincipal,
    requestId: string,
  ): Promise<CustomerRequestView> {
    await this.expireDue({ consumerId: consumer.consumerId, requestId });
    return this.toCustomerView(await this.findOne({ consumerId: consumer.consumerId, requestId }));
  }

  async cancel(
    consumer: ConsumerPrincipal,
    requestId: string,
    input: CancelRequestDto,
  ): Promise<CustomerRequestView> {
    const owned = { consumerId: consumer.consumerId, requestId };
    await this.expireDue(owned);
    const reason = input.reason?.trim();
    const updated = await this.transition(
      {
        ...owned,
        $or: [{ status: 'Pending' }, { status: 'Accepted', orderId: { $exists: false } }],
      },
      'Cancelled',
      { by: 'customer', actorId: consumer.consumerId, note: reason },
      reason ? { cancelReason: reason } : {},
    );
    if (!updated) {
      const current = await this.findOne(owned);
      throw new ConflictException(
        current.orderId
          ? 'The shop has already started your order — call the shop to cancel'
          : `This request is already ${current.status.toLowerCase()}`,
      );
    }
    return this.toCustomerView(updated);
  }

  // ── Shop side ─────────────────────────────────────────────────────────────

  async listForShop(
    shop: ShopPrincipal,
    query: ListRequestsQueryDto,
  ): Promise<PageOf<ShopRequestView>> {
    this.assertCanRead(shop);
    await this.expireDue({ branchId: shop.branchId });
    const page = await this.page({ tenantId: shop.tenantId, branchId: shop.branchId }, query);
    return { ...page, items: page.items.map((request) => this.toShopView(request)) };
  }

  /** Counts for the "Online Requests" tab badge. */
  async summaryForShop(shop: ShopPrincipal): Promise<ShopRequestSummary> {
    this.assertCanRead(shop);
    await this.expireDue({ branchId: shop.branchId });
    const rows = await this.database.requests
      .aggregate<{
        _id: RequestStatus;
        count: number;
      }>([
        { $match: { tenantId: shop.tenantId, branchId: shop.branchId } },
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ])
      .exec();
    const count = (status: RequestStatus): number =>
      rows.find((row) => row._id === status)?.count ?? 0;
    return {
      pending: count('Pending'),
      accepted: count('Accepted'),
      completed: count('Completed'),
      declined: count('Declined'),
      cancelled: count('Cancelled'),
      expired: count('Expired'),
    };
  }

  async getForShop(shop: ShopPrincipal, requestId: string): Promise<ShopRequestView> {
    this.assertCanRead(shop);
    await this.expireDue({ branchId: shop.branchId, requestId });
    return this.toShopView(await this.findOne(this.shopFilter(shop, requestId)));
  }

  async accept(
    shop: ShopPrincipal,
    requestId: string,
    input: AcceptRequestDto,
  ): Promise<ShopRequestView> {
    this.assertCanAct(shop);
    const scope = this.shopFilter(shop, requestId);
    await this.expireDue(scope);
    const current = await this.findOne(scope);

    const confirmedAt = input.confirmedAt
      ? new Date(input.confirmedAt).toISOString()
      : istInstant(current.preferredDate, current.preferredSlot.start);
    if (input.confirmedAt && Date.parse(confirmedAt) < Date.now() - 60 * 60_000) {
      throw new BadRequestException('The confirmed time is in the past');
    }

    // Retry the customer-list link if customer-service was down when the request came in.
    const shopCustomerId =
      current.shopCustomerId ??
      (await this.shopServices.linkOnlineCustomer(shop.tenantId, shop.branchId, {
        consumerId: current.consumerId,
        name: current.customer.name,
        mobile: current.customer.mobile,
        email: current.customer.email || undefined,
        address: current.address?.formatted,
      }));

    const note = input.note?.trim();
    const updated = await this.transition(
      { ...scope, status: 'Pending' },
      'Accepted',
      { by: 'shop', actorId: shop.actorId, note },
      {
        confirmedAt,
        ...(note ? { shopNote: note } : {}),
        ...(shopCustomerId ? { shopCustomerId } : {}),
      },
    );
    if (!updated) throw this.alreadyHandled(await this.findOne(scope));
    return this.toShopView(updated);
  }

  async decline(
    shop: ShopPrincipal,
    requestId: string,
    input: DeclineRequestDto,
  ): Promise<ShopRequestView> {
    this.assertCanAct(shop);
    const scope = this.shopFilter(shop, requestId);
    await this.expireDue(scope);
    const reason = input.reason.trim();
    const updated = await this.transition(
      {
        ...scope,
        $or: [{ status: 'Pending' }, { status: 'Accepted', orderId: { $exists: false } }],
      },
      'Declined',
      { by: 'shop', actorId: shop.actorId, note: reason },
      { declineReason: reason },
    );
    if (!updated) throw this.alreadyHandled(await this.findOne(scope));
    return this.toShopView(updated);
  }

  /** After the shop creates the order for an accepted request, link the two. */
  async linkOrder(
    shop: ShopPrincipal,
    requestId: string,
    input: LinkOrderDto,
  ): Promise<ShopRequestView> {
    this.assertCanAct(shop);
    const scope = this.shopFilter(shop, requestId);
    const current = await this.findOne(scope);
    if (current.status !== 'Accepted' || current.orderId) {
      throw current.orderId
        ? new ConflictException(`Order ${current.orderNumber} is already linked to this request`)
        : new ConflictException('Accept the request before linking an order');
    }

    const order = await this.shopServices.findShopOrder(shop, input.orderId);
    if (current.shopCustomerId && order.customerId !== current.shopCustomerId) {
      throw new ConflictException(
        `Order ${order.orderNumber} is for a different customer than this request`,
      );
    }

    let updated: ServiceRequestDocument | null;
    try {
      updated = await this.transition(
        { ...scope, status: 'Accepted', orderId: { $exists: false } },
        'Accepted',
        { by: 'shop', actorId: shop.actorId, note: `Order ${order.orderNumber} created` },
        { orderId: order.orderId, orderNumber: order.orderNumber },
      );
    } catch (error) {
      if ((error as { code?: number }).code === 11000) {
        throw new ConflictException(
          `Order ${order.orderNumber} is already linked to another request`,
        );
      }
      throw error;
    }
    if (!updated) throw this.alreadyHandled(await this.findOne(scope));
    return this.toShopView(updated);
  }

  async complete(
    shop: ShopPrincipal,
    requestId: string,
    input: CompleteRequestDto,
  ): Promise<ShopRequestView> {
    this.assertCanAct(shop);
    const scope = this.shopFilter(shop, requestId);
    const note = input.note?.trim();
    const updated = await this.transition(
      { ...scope, status: 'Accepted' },
      'Completed',
      { by: 'shop', actorId: shop.actorId, note },
      {},
    );
    if (!updated) {
      const current = await this.findOne(scope);
      throw current.status === 'Pending'
        ? new ConflictException('Accept the request before completing it')
        : this.alreadyHandled(current);
    }
    return this.toShopView(updated);
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  /**
   * Lazily expires unanswered requests: every read or action first marks
   * Pending requests older than 48 hours as Expired, so no scheduler is needed.
   */
  async expireDue(scope: FilterQuery<ServiceRequestDocument>): Promise<number> {
    const now = new Date().toISOString();
    const result = await this.database.requests
      .updateMany(
        { ...scope, status: 'Pending', expiresAt: { $lte: now } },
        {
          $set: { status: 'Expired', updatedAt: now },
          $push: {
            statusHistory: {
              status: 'Expired',
              at: now,
              by: 'system',
              note: `No reply from the shop within ${REQUEST_EXPIRY_HOURS} hours`,
            },
          },
        },
      )
      .exec();
    return result.modifiedCount;
  }

  private async findBookableShop(shopId: string): Promise<ShopListingDocument> {
    const listing = await this.database.listings
      .findOne({ branchId: shopId, searchable: true }, { _id: 0 })
      .lean()
      .exec();
    if (!listing?.location) throw new NotFoundException('Shop not found');

    const live = await this.tenantDirectory.findSummaries([listing.tenantId]);
    const tenant = live?.get(listing.tenantId);
    const active = live ? tenant?.status === 'Active' : listing.tenantStatus === 'Active';
    if (!active) throw new NotFoundException('Shop not found');
    return tenant
      ? { ...listing, shopName: tenant.businessName, ownerPhone: tenant.ownerPhone }
      : listing;
  }

  private assertDateAndSlot(
    listing: ShopListingDocument,
    input: CreateServiceRequestDto,
    now: Date,
  ): void {
    const today = istToday(now);
    if (!isRealDate(input.preferredDate)) {
      throw new BadRequestException('preferredDate is not a valid date');
    }
    if (input.preferredDate < today || input.preferredDate > addDays(today, MAX_DAYS_AHEAD)) {
      throw new BadRequestException(`Choose a date from today up to ${MAX_DAYS_AHEAD} days ahead`);
    }
    if (input.preferredSlot.end <= input.preferredSlot.start) {
      throw new BadRequestException('The time slot must end after it starts');
    }
    if (
      input.preferredDate === today &&
      istInstant(today, input.preferredSlot.end) <= now.toISOString()
    ) {
      throw new BadRequestException('That time slot has already passed today');
    }
    const weekday = new Date(`${input.preferredDate}T00:00:00Z`).getUTCDay();
    if (listing.openingHours.find((day) => day.day === weekday)?.closed) {
      throw new BadRequestException('The shop is closed on that day');
    }
  }

  private shopFilter(
    shop: ShopPrincipal,
    requestId: string,
  ): { tenantId: string; branchId: string; requestId: string } {
    return { tenantId: shop.tenantId, branchId: shop.branchId, requestId };
  }

  private async findOne(
    filter: FilterQuery<ServiceRequestDocument>,
  ): Promise<ServiceRequestDocument> {
    const request = await this.database.requests.findOne(filter, { _id: 0 }).lean().exec();
    if (!request) throw new NotFoundException('Request not found');
    return request;
  }

  /** Atomic status change: only applies if `filter` (including the expected status) still matches. */
  private async transition(
    filter: FilterQuery<ServiceRequestDocument>,
    status: RequestStatus,
    entry: Omit<RequestHistoryEntry, 'status' | 'at'>,
    fields: Partial<ServiceRequestDocument>,
  ): Promise<ServiceRequestDocument | null> {
    const at = new Date().toISOString();
    const history: RequestHistoryEntry = {
      status,
      at,
      by: entry.by,
      ...(entry.actorId ? { actorId: entry.actorId } : {}),
      ...(entry.note ? { note: entry.note } : {}),
    };
    const update: UpdateQuery<ServiceRequestDocument> = {
      $set: { ...fields, status, updatedAt: at },
      $push: { statusHistory: history },
    };
    return this.database.requests
      .findOneAndUpdate(filter, update, { new: true, projection: { _id: 0 } })
      .lean()
      .exec();
  }

  private async page(
    filter: FilterQuery<ServiceRequestDocument>,
    query: ListRequestsQueryDto,
  ): Promise<PageOf<ServiceRequestDocument>> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const fullFilter = { ...filter, ...(query.status ? { status: query.status } : {}) };
    const [items, total] = await Promise.all([
      this.database.requests
        .find(fullFilter, { _id: 0 })
        .sort({ createdAt: -1 })
        .skip((page - 1) * limit)
        .limit(limit)
        .lean()
        .exec(),
      this.database.requests.countDocuments(fullFilter),
    ]);
    return { items, page, limit, total };
  }

  private alreadyHandled(current: ServiceRequestDocument): ConflictException {
    return new ConflictException(`This request is already ${current.status.toLowerCase()}`);
  }

  private assertCanRead(shop: ShopPrincipal): void {
    if (!hasPermission(shop.roleCode, shop.permissions, Permissions.ordersRead)) {
      throw new ForbiddenException('Order access is required to see online requests');
    }
  }

  private assertCanAct(shop: ShopPrincipal): void {
    if (!hasPermission(shop.roleCode, shop.permissions, Permissions.ordersWrite)) {
      throw new ForbiddenException('Order permission is required to answer online requests');
    }
  }

  private baseView(
    request: ServiceRequestDocument,
  ): Omit<CustomerRequestView, 'address' | 'canCancel' | 'history'> {
    return {
      requestId: request.requestId,
      requestNumber: request.requestNumber,
      shop: {
        shopId: request.branchId,
        shopName: request.shop.shopName,
        branchName: request.shop.branchName,
        phone: request.shop.phone,
      },
      category: request.category,
      categoryLabel: CATEGORY_LABELS[request.category],
      requestType: request.requestType,
      description: request.description,
      items: request.items,
      preferredDate: request.preferredDate,
      preferredSlot: request.preferredSlot,
      status: request.status,
      confirmedAt: request.confirmedAt,
      shopNote: request.shopNote,
      declineReason: request.declineReason,
      cancelReason: request.cancelReason,
      orderNumber: request.orderNumber,
      expiresAt: request.status === 'Pending' ? request.expiresAt : undefined,
      createdAt: request.createdAt,
      updatedAt: request.updatedAt,
    };
  }

  private toCustomerView(request: ServiceRequestDocument): CustomerRequestView {
    return {
      ...this.baseView(request),
      address: request.address
        ? { label: request.address.label, formatted: request.address.formatted }
        : undefined,
      canCancel:
        request.status === 'Pending' || (request.status === 'Accepted' && !request.orderId),
      // Staff identities are internal to the shop.
      history: request.statusHistory.map((entry) => ({
        status: entry.status,
        at: entry.at,
        by: entry.by,
        ...(entry.note ? { note: entry.note } : {}),
      })),
    };
  }

  private toShopView(request: ServiceRequestDocument): ShopRequestView {
    const point = request.address ? fromGeoJson(request.address.location) : undefined;
    const openAccepted = request.status === 'Accepted' && !request.orderId;
    return {
      ...this.baseView(request),
      customer: request.customer,
      shopCustomerId: request.shopCustomerId,
      address:
        request.address && point
          ? {
              label: request.address.label,
              formatted: request.address.formatted,
              landmark: request.address.landmark,
              contactName: request.address.contactName,
              contactPhone: request.address.contactPhone,
              latitude: point.latitude,
              longitude: point.longitude,
            }
          : undefined,
      distanceKm: request.distanceKm,
      orderId: request.orderId,
      actions: {
        accept: request.status === 'Pending',
        decline: request.status === 'Pending' || openAccepted,
        linkOrder: openAccepted,
        complete: request.status === 'Accepted',
      },
      history: request.statusHistory,
    };
  }
}
