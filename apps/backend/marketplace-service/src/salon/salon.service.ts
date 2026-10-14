import { randomUUID } from 'node:crypto';

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { hasPermission, Permissions } from '@nexoraa/shared';
import type { FilterQuery } from 'mongoose';

import {
  MarketplaceDatabase,
  type SalonBookedPart,
  type SalonBookingSnapshot,
  type SalonConfigDocument,
  type SalonMenuItem,
  type SalonStaffMember,
  type ServiceRequestDocument,
  type ShopListingDocument,
} from '../platform/marketplace.database';
import type { ShopPrincipal } from '../platform/marketplace.types';
import { ShopServicesClient } from '../platform/shop-services.client';
import { TenantDirectoryClient } from '../platform/tenant-directory.client';
import type { AssignSalonStaffDto, SalonWalkInDto, SaveSalonConfigDto } from './salon.dto';
import {
  assignParts,
  buildSlots,
  formatClock,
  isSlotStart,
  openWindow,
  parseClock,
  slotsNeeded,
  type HeldPart,
  type PartNeed,
  type SlotView,
} from './salon.logic';

const IST_OFFSET_MS = 330 * 60_000;
const DAY_MS = 86_400_000;
const MAX_DAYS_AHEAD = 30;
const DEFAULT_SLOT_MINUTES = 30;
const TAKEN = 'That time was just taken. Please pick another slot.';

export interface SalonConfigView {
  readonly configured: boolean;
  readonly slotMinutes: number;
  readonly staff: readonly SalonStaffMember[];
  readonly menu: readonly SalonMenuItem[];
}

export interface SalonMenuView {
  readonly configured: boolean;
  readonly slotMinutes: number;
  readonly menu: readonly SalonMenuItem[];
  readonly payment: 'pay_at_shop';
}

export interface SalonSlotsView {
  readonly date: string;
  readonly slotMinutes: number;
  readonly totalMinutes: number;
  readonly totalPrice: number;
  readonly closed: boolean;
  readonly slots: readonly SlotView[];
}

export interface SalonAppointmentView {
  readonly requestId: string;
  readonly requestNumber: string;
  readonly customerName: string;
  readonly status: string;
  readonly service: string;
  readonly start: string;
  readonly end: string;
}

export interface SalonScheduleView {
  readonly date: string;
  readonly closed: boolean;
  readonly slotMinutes: number;
  readonly staff: readonly (SalonStaffMember & {
    readonly appointments: readonly SalonAppointmentView[];
  })[];
}

export interface SalonWalkInView {
  readonly requestId: string;
  readonly requestNumber: string;
  readonly date: string;
  readonly startMinute: number;
  readonly endMinute: number;
  readonly parts: readonly SalonBookedPart[];
  readonly totalPrice: number;
}

export interface SalonPlan {
  readonly snapshot: SalonBookingSnapshot;
  readonly config: SalonConfigDocument;
  readonly description: string;
  readonly items: readonly { readonly name: string; readonly quantity: number }[];
  readonly slot: { readonly start: string; readonly end: string };
}

const istDate = (now: Date): string =>
  new Date(now.getTime() + IST_OFFSET_MS).toISOString().slice(0, 10);

const istMinutes = (now: Date): number => {
  const shifted = new Date(now.getTime() + IST_OFFSET_MS);
  return shifted.getUTCHours() * 60 + shifted.getUTCMinutes();
};

const needOf = (item: SalonMenuItem, slotMinutes: number): PartNeed => ({
  serviceId: item.serviceId,
  role: item.role,
  slots: slotsNeeded(item.durationMinutes, slotMinutes),
});

/** Only salons run the appointment diary; every other business is untouched by this module. */
@Injectable()
export class SalonService {
  constructor(
    private readonly database: MarketplaceDatabase,
    private readonly tenantDirectory: TenantDirectoryClient,
    @Optional() private readonly shopServices?: ShopServicesClient,
  ) {}

  // ── Shop side ─────────────────────────────────────────────────────────────

  async getConfig(shop: ShopPrincipal): Promise<SalonConfigView> {
    this.assertCanRead(shop);
    await this.assertSalonBusiness(shop.tenantId);
    return this.toConfigView(await this.findConfig(shop.branchId));
  }

  async saveConfig(shop: ShopPrincipal, input: SaveSalonConfigDto): Promise<SalonConfigView> {
    if (!hasPermission(shop.roleCode, shop.permissions, Permissions.branchesWrite)) {
      throw new ForbiddenException('Only the owner or a branch manager can change salon booking');
    }
    await this.assertSalonBusiness(shop.tenantId);

    const staffIds = new Set<string>();
    const staff: SalonStaffMember[] = input.staff.map((member) => {
      const staffId = member.staffId?.trim() || randomUUID();
      if (staffIds.has(staffId)) throw new BadRequestException('Two people share the same id');
      staffIds.add(staffId);
      return { staffId, name: member.name.trim(), role: member.role.trim() };
    });
    const roles = new Set(staff.map((member) => member.role));

    const serviceIds = new Set<string>();
    const menu: SalonMenuItem[] = input.menu.map((item) => {
      const serviceId = item.serviceId?.trim() || randomUUID();
      if (serviceIds.has(serviceId)) throw new BadRequestException('Two menu items share an id');
      serviceIds.add(serviceId);
      const role = item.role.trim();
      if (!roles.has(role)) {
        throw new BadRequestException(
          `${item.name.trim()} needs a ${role}. Add one to your team first.`,
        );
      }
      return {
        serviceId,
        name: item.name.trim(),
        price: item.price,
        durationMinutes: item.durationMinutes,
        role,
        ...(item.catalogServiceId && item.catalogItemCategoryId
          ? {
              catalogServiceId: item.catalogServiceId,
              catalogItemCategoryId: item.catalogItemCategoryId,
            }
          : {}),
      };
    });
    if (new Set(menu.map((item) => item.name.toLowerCase())).size !== menu.length) {
      throw new BadRequestException('Each menu service needs a different name');
    }

    const now = new Date().toISOString();
    const existing = await this.database.salonConfigs
      .findOne({ branchId: shop.branchId }, { createdAt: 1, tenantId: 1 })
      .lean()
      .exec();
    if (existing && existing.tenantId !== shop.tenantId) {
      throw new NotFoundException('Branch not found');
    }
    const document: SalonConfigDocument = {
      branchId: shop.branchId,
      tenantId: shop.tenantId,
      slotMinutes: input.slotMinutes,
      staff,
      menu,
      updatedBy: shop.actorId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    };
    await this.database.salonConfigs
      .replaceOne({ branchId: shop.branchId }, document, { upsert: true })
      .exec();
    return this.toConfigView(document);
  }

  /** The day's diary for the owner: each person with their appointments. */
  async schedule(shop: ShopPrincipal, date: string): Promise<SalonScheduleView> {
    this.assertCanRead(shop);
    await this.assertSalonBusiness(shop.tenantId);
    this.assertDate(date);
    const [config, listing] = await Promise.all([
      this.findConfig(shop.branchId),
      this.database.listings
        .findOne({ branchId: shop.branchId, tenantId: shop.tenantId }, { openingHours: 1 })
        .lean()
        .exec(),
    ]);
    const slotMinutes = config?.slotMinutes ?? DEFAULT_SLOT_MINUTES;
    const closed = !listing || !openWindow(listing.openingHours, date);
    const rows = await this.heldRows(shop.branchId, date, new Date());
    const staff = (config?.staff ?? []).map((member) => ({
      ...member,
      appointments: rows
        .flatMap((row) =>
          row
            .salon!.parts.filter((part) => part.staffId === member.staffId)
            .map((part) => ({
              requestId: row.requestId,
              requestNumber: row.requestNumber,
              customerName: row.customer.name,
              status: row.status,
              service: part.name,
              start: formatClock(part.startMinute),
              end: formatClock(part.endMinute),
            })),
        )
        .sort((a, b) => a.start.localeCompare(b.start)),
    }));
    return { date, closed, slotMinutes, staff };
  }

  /** Owner (or manager) picks who does which service on an existing booking. */
  async assignStaff(
    shop: ShopPrincipal,
    requestId: string,
    input: AssignSalonStaffDto,
  ): Promise<{ readonly requestId: string; readonly parts: readonly SalonBookedPart[] }> {
    if (!hasPermission(shop.roleCode, shop.permissions, Permissions.ordersAssign)) {
      throw new ForbiddenException('Only the owner or a branch manager can assign staff');
    }
    const request = await this.database.requests
      .findOne(
        { requestId, tenantId: shop.tenantId, branchId: shop.branchId, salon: { $exists: true } },
        { _id: 0 },
      )
      .lean()
      .exec();
    if (!request?.salon) throw new NotFoundException('Appointment not found');
    if (request.status !== 'Pending' && request.status !== 'Accepted') {
      throw new ConflictException(`This appointment is already ${request.status.toLowerCase()}`);
    }
    const config = await this.requireConfig(shop.branchId);
    const others = (await this.heldRows(shop.branchId, request.preferredDate, new Date())).filter(
      (row) => row.requestId !== requestId,
    );
    const held = this.heldParts(others);

    const parts = request.salon.parts.map((part) => {
      const pick = input.assignments.find((entry) => entry.serviceId === part.serviceId);
      if (!pick || pick.staffId === part.staffId) return part;
      const member = config.staff.find((candidate) => candidate.staffId === pick.staffId);
      if (!member || member.role !== part.role) {
        throw new BadRequestException(`${part.name} needs a ${part.role}`);
      }
      if (
        held.some(
          (other) =>
            other.staffId === member.staffId &&
            other.start < part.endMinute &&
            other.end > part.startMinute,
        )
      ) {
        throw new ConflictException(`${member.name} is busy at that time`);
      }
      return { ...part, staffId: member.staffId, staffName: member.name };
    });
    await this.database.requests
      .updateOne(
        { requestId },
        { $set: { 'salon.parts': parts, updatedAt: new Date().toISOString() } },
      )
      .exec();
    return { requestId, parts };
  }

  /**
   * A customer who walked into the shop: gives each chosen service a free person of the right
   * role starting at the next free slot today, and records it as an accepted appointment so the
   * time is held and an order can be made from it.
   */
  async walkIn(shop: ShopPrincipal, input: SalonWalkInDto): Promise<SalonWalkInView> {
    if (!hasPermission(shop.roleCode, shop.permissions, Permissions.ordersWrite)) {
      throw new ForbiddenException('Order permission is required to add a walk-in');
    }
    await this.assertSalonBusiness(shop.tenantId);
    if (!this.shopServices) throw new NotFoundException('Walk-ins are not available');
    const listing = await this.database.listings
      .findOne({ branchId: shop.branchId, tenantId: shop.tenantId }, { _id: 0 })
      .lean()
      .exec();
    if (!listing) throw new NotFoundException('Save your shop listing first');
    const config = await this.requireConfig(shop.branchId);
    const customer = await this.shopServices.getCustomer(shop, input.customerId);

    const now = new Date();
    const date = istDate(now);
    const window = openWindow(listing.openingHours, date);
    if (!window) throw new BadRequestException('The salon is closed today');
    const slot = config.slotMinutes;
    let start = window.open + Math.max(0, Math.ceil((istMinutes(now) - window.open) / slot)) * slot;
    let plan: SalonPlan | undefined;
    for (; start + slot <= window.close; start += slot) {
      try {
        plan = await this.plan(listing, date, formatClock(start), input.serviceIds, now);
        break;
      } catch (error) {
        if (error instanceof ConflictException) continue;
        if (error instanceof BadRequestException && /fit before/.test(error.message)) break;
        throw error;
      }
    }
    if (!plan) {
      throw new ConflictException('No one is free for these services for the rest of today');
    }

    const year = date.slice(0, 4);
    const sequence = await this.database.nextSequence(`serviceRequest-${year}`);
    const at = now.toISOString();
    const request: ServiceRequestDocument = {
      requestId: randomUUID(),
      requestNumber: `SR-${year}-${String(sequence).padStart(6, '0')}`,
      consumerId: `walk-in:${customer.id}`,
      customer: { name: customer.name, mobile: customer.mobile, email: '' },
      tenantId: shop.tenantId,
      branchId: shop.branchId,
      shop: {
        shopName: listing.shopName,
        branchName: listing.branchName,
        phone: listing.bookingPhone || listing.ownerPhone,
      },
      category: 'salon',
      requestType: 'visit_shop',
      description: plan.description,
      items: plan.items.map((item) => ({ ...item })),
      preferredDate: date,
      preferredSlot: plan.slot,
      status: 'Accepted',
      confirmedAt: new Date(`${date}T${plan.slot.start}:00+05:30`).toISOString(),
      shopCustomerId: customer.id,
      salon: plan.snapshot,
      expiresAt: new Date(now.getTime() + 365 * DAY_MS).toISOString(),
      statusHistory: [
        { status: 'Accepted', at, by: 'shop', actorId: shop.actorId, note: 'Walk-in' },
      ],
      createdAt: at,
      updatedAt: at,
    };
    await this.database.requests.create(request);
    await this.settle(request, plan.config);
    const saved = await this.database.requests
      .findOne({ requestId: request.requestId }, { _id: 0 })
      .lean()
      .exec();
    const booked = saved?.salon ?? plan.snapshot;
    return {
      requestId: request.requestId,
      requestNumber: request.requestNumber,
      date,
      startMinute: booked.startMinute,
      endMinute: booked.endMinute,
      parts: booked.parts,
      totalPrice: booked.totalPrice,
    };
  }

  // ── Customer side ─────────────────────────────────────────────────────────

  async menuForCustomer(shopId: string): Promise<SalonMenuView> {
    const listing = await this.findSalonListing(shopId);
    const config = await this.findConfig(listing.branchId);
    const view = this.toConfigView(config);
    return {
      configured: view.configured,
      slotMinutes: view.slotMinutes,
      menu: view.menu,
      payment: 'pay_at_shop',
    };
  }

  async slotsForCustomer(
    shopId: string,
    date: string,
    serviceIds: readonly string[] = [],
  ): Promise<SalonSlotsView> {
    this.assertDate(date);
    const listing = await this.findSalonListing(shopId);
    const config = await this.requireConfig(listing.branchId);
    const chosen = this.pickServices(config, serviceIds, false);
    const base = {
      date,
      slotMinutes: config.slotMinutes,
      totalMinutes: chosen.reduce((sum, item) => sum + item.durationMinutes, 0),
      totalPrice: chosen.reduce((sum, item) => sum + item.price, 0),
    };

    const window = openWindow(listing.openingHours, date);
    if (!window) return { ...base, closed: true, slots: [] };
    const now = new Date();
    const rows = await this.heldRows(listing.branchId, date, now);
    return {
      ...base,
      closed: false,
      slots: buildSlots({
        ...window,
        slotMinutes: config.slotMinutes,
        staff: config.staff,
        held: this.heldParts(rows),
        needs: chosen.map((item) => needOf(item, config.slotMinutes)),
        earliestStart: date === istDate(now) ? istMinutes(now) : undefined,
      }),
    };
  }

  // ── Used by RequestService when a customer books a salon appointment ─────

  /**
   * Turns the chosen menu services and start time into the booking to hold:
   * each service gets a free staff member of the right role, back to back.
   * Throws when the time cannot be served, so a taken slot is never booked.
   */
  async plan(
    listing: ShopListingDocument,
    date: string,
    startClock: string,
    serviceIds: readonly string[],
    now: Date,
  ): Promise<SalonPlan> {
    if (!listing.categories.includes('salon')) {
      throw new BadRequestException(`${listing.shopName} is not a salon`);
    }
    const config = await this.requireConfig(listing.branchId);
    const chosen = this.pickServices(config, serviceIds, true);
    const window = openWindow(listing.openingHours, date);
    if (!window) throw new BadRequestException('The salon is closed on that day');

    const start = parseClock(startClock);
    if (!isSlotStart(window.open, window.close, config.slotMinutes, start)) {
      throw new BadRequestException('Choose one of the listed time slots');
    }
    const needs = chosen.map((item) => needOf(item, config.slotMinutes));
    const end = start + needs.reduce((sum, need) => sum + need.slots, 0) * config.slotMinutes;
    if (end > window.close) {
      throw new BadRequestException('These services do not fit before the salon closes');
    }
    if (date === istDate(now) && start < istMinutes(now)) {
      throw new BadRequestException('That time slot has already passed today');
    }

    const rows = await this.heldRows(listing.branchId, date, now);
    const result = assignParts({
      staff: config.staff,
      held: this.heldParts(rows),
      needs,
      start,
      slotMinutes: config.slotMinutes,
    });
    if (!result.ok) {
      if (result.state === 'unavailable') {
        throw new BadRequestException('The salon has no one for one of those services yet');
      }
      throw new ConflictException(TAKEN);
    }

    const parts: SalonBookedPart[] = result.parts.map((assigned) => {
      const item = chosen.find((candidate) => candidate.serviceId === assigned.serviceId)!;
      const member = config.staff.find((candidate) => candidate.staffId === assigned.staffId)!;
      return {
        serviceId: item.serviceId,
        name: item.name,
        price: item.price,
        durationMinutes: item.durationMinutes,
        role: item.role,
        ...(item.catalogServiceId && item.catalogItemCategoryId
          ? {
              catalogServiceId: item.catalogServiceId,
              catalogItemCategoryId: item.catalogItemCategoryId,
            }
          : {}),
        staffId: member.staffId,
        staffName: member.name,
        startMinute: assigned.start,
        endMinute: assigned.end,
      };
    });
    return {
      config,
      description: chosen.map((item) => item.name).join(', '),
      items: chosen.map((item) => ({ name: item.name, quantity: 1 })),
      slot: { start: formatClock(start), end: formatClock(end) },
      snapshot: {
        parts,
        totalPrice: chosen.reduce((sum, item) => sum + item.price, 0),
        totalMinutes: chosen.reduce((sum, item) => sum + item.durationMinutes, 0),
        startMinute: start,
        endMinute: end,
        payment: 'pay_at_shop',
      },
    };
  }

  /**
   * Two customers can pass the free check at the same moment. After saving,
   * the earlier booking keeps its staff; the later one is given someone else
   * of the same role, or removed when nobody is left.
   */
  async settle(request: ServiceRequestDocument, config: SalonConfigDocument): Promise<void> {
    const mine = request.salon;
    if (!mine) return;
    const rows = (await this.heldRows(request.branchId, request.preferredDate, new Date())).sort(
      (a, b) => a.createdAt.localeCompare(b.createdAt) || a.requestId.localeCompare(b.requestId),
    );
    const position = rows.findIndex((row) => row.requestId === request.requestId);
    const earlier = this.heldParts(rows.slice(0, Math.max(0, position)));
    const everyoneElse = this.heldParts(rows.filter((row) => row.requestId !== request.requestId));
    const overlapping = (parts: readonly HeldPart[], staffId: string, from: number, to: number) =>
      parts.some((part) => part.staffId === staffId && part.start < to && part.end > from);

    let changed = false;
    const parts = mine.parts.map((part) => {
      if (!overlapping(earlier, part.staffId, part.startMinute, part.endMinute)) return part;
      const swap = config.staff.find(
        (member) =>
          member.role === part.role &&
          !overlapping(everyoneElse, member.staffId, part.startMinute, part.endMinute),
      );
      if (!swap) return undefined;
      changed = true;
      return { ...part, staffId: swap.staffId, staffName: swap.name };
    });
    if (parts.some((part) => part === undefined)) {
      await this.database.requests.deleteOne({ requestId: request.requestId }).exec();
      throw new ConflictException(TAKEN);
    }
    if (changed) {
      await this.database.requests
        .updateOne({ requestId: request.requestId }, { $set: { 'salon.parts': parts } })
        .exec();
    }
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  private findConfig(branchId: string): Promise<SalonConfigDocument | null> {
    return this.database.salonConfigs.findOne({ branchId }, { _id: 0 }).lean().exec();
  }

  private async requireConfig(branchId: string): Promise<SalonConfigDocument> {
    const config = await this.findConfig(branchId);
    if (!config || config.menu.length === 0 || config.staff.length === 0) {
      throw new BadRequestException('This salon has not set up online booking yet');
    }
    return config;
  }

  private toConfigView(config: SalonConfigDocument | null): SalonConfigView {
    return {
      configured: !!config && config.menu.length > 0 && config.staff.length > 0,
      slotMinutes: config?.slotMinutes ?? DEFAULT_SLOT_MINUTES,
      staff: config?.staff ?? [],
      menu: config?.menu ?? [],
    };
  }

  private pickServices(
    config: SalonConfigDocument,
    serviceIds: readonly string[],
    required: boolean,
  ): SalonMenuItem[] {
    const unique = [...new Set(serviceIds)];
    if (required && unique.length === 0) {
      throw new BadRequestException('Choose at least one service');
    }
    return unique.map((id) => {
      const found = config.menu.find((item) => item.serviceId === id);
      if (!found) throw new BadRequestException('One of the chosen services is no longer offered');
      return found;
    });
  }

  /** Salon appointments still holding time on a day: confirmed, or waiting and not yet expired. */
  private heldRows(branchId: string, date: string, now: Date): Promise<ServiceRequestDocument[]> {
    const filter: FilterQuery<ServiceRequestDocument> = {
      branchId,
      preferredDate: date,
      salon: { $exists: true },
      $or: [{ status: 'Accepted' }, { status: 'Pending', expiresAt: { $gt: now.toISOString() } }],
    };
    return this.database.requests.find(filter, { _id: 0 }).lean().exec();
  }

  private heldParts(rows: readonly ServiceRequestDocument[]): HeldPart[] {
    return rows.flatMap((row) =>
      row.salon!.parts.map((part) => ({
        staffId: part.staffId,
        start: part.startMinute,
        end: part.endMinute,
        accepted: row.status === 'Accepted',
      })),
    );
  }

  private async findSalonListing(shopId: string): Promise<ShopListingDocument> {
    const listing = await this.database.listings
      .findOne({ branchId: shopId, searchable: true }, { _id: 0 })
      .lean()
      .exec();
    if (!listing || !listing.categories.includes('salon')) {
      throw new NotFoundException('Salon not found');
    }
    return listing;
  }

  private async assertSalonBusiness(tenantId: string): Promise<void> {
    const profile = await this.tenantDirectory.getMarketplaceProfile(tenantId);
    if (!profile.services.includes('salon')) {
      throw new ForbiddenException('Appointment booking is only for salon businesses');
    }
  }

  private assertCanRead(shop: ShopPrincipal): void {
    if (!hasPermission(shop.roleCode, shop.permissions, Permissions.ordersRead)) {
      throw new ForbiddenException('Order access is required to see the salon schedule');
    }
  }

  private assertDate(date: string): void {
    const parsed = new Date(`${date}T00:00:00Z`);
    if (Number.isNaN(parsed.getTime()) || parsed.toISOString().slice(0, 10) !== date) {
      throw new BadRequestException('date is not a valid date');
    }
    const today = new Date(`${istDate(new Date())}T00:00:00Z`).getTime();
    const days = Math.round((parsed.getTime() - today) / DAY_MS);
    if (days < -1 || days > MAX_DAYS_AHEAD) {
      throw new BadRequestException(`Choose a date from today up to ${MAX_DAYS_AHEAD} days ahead`);
    }
  }
}
