import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';

import { AddressService } from '../address/address.service';
import {
  distanceMeters,
  fromGeoJson,
  isInIndia,
  isOpenAt,
  parseClock,
  roundKm,
  toGeoJson,
  todayHours,
} from '../platform/geo';
import {
  MarketplaceDatabase,
  type OpeningHoursDay,
  type ShopAddress,
  type ShopListingDocument,
} from '../platform/marketplace.database';
import type {
  ConsumerPrincipal,
  GeoPoint,
  ServiceMode,
  ShopCategory,
  ShopPrincipal,
} from '../platform/marketplace.types';
import { normalizeShopPhone } from '../platform/phone';
import {
  TenantDirectoryClient,
  type TenantMarketplaceProfile,
  type TenantSummary,
} from '../platform/tenant-directory.client';
import type {
  OpeningHoursDto,
  ShopDetailQueryDto,
  ShopSearchQueryDto,
  UpsertShopListingDto,
} from './listing.dto';

/** Fields the shop still has to fill before customers can find it. */
export type ListingMissingField =
  | 'streetAddress'
  | 'city'
  | 'state'
  | 'postalCode'
  | 'location'
  | 'serviceModes'
  | 'openingHours';

/** What the shop sees on its "Shop listing" settings screen. */
export interface ShopListingView {
  readonly branchId: string;
  readonly tenantId: string;
  readonly shopName: string;
  readonly branchName: string;
  readonly categories: readonly ShopCategory[];
  readonly address: ShopAddress;
  readonly latitude?: number;
  readonly longitude?: number;
  readonly bookingPhone?: string;
  readonly ownerPhone: string;
  /** bookingPhone, or the owner phone when it is empty. */
  readonly phoneShownToCustomers: string;
  readonly serviceModes: readonly ServiceMode[];
  readonly serviceRadiusKm: number;
  readonly openingHours: readonly OpeningHoursDay[];
  readonly about?: string;
  readonly isListed: boolean;
  /** False until the listing has been saved once with every required field. */
  readonly saved: boolean;
  readonly isComplete: boolean;
  readonly missingFields: readonly ListingMissingField[];
  readonly isVisibleToCustomers: boolean;
  /** Why customers cannot see the shop, when they cannot. */
  readonly hiddenReason?: 'incomplete' | 'unlisted' | 'business_inactive';
  readonly updatedAt?: string;
}

/** One row of the customer's "shops near me" list. */
export interface ShopSearchResult {
  readonly shopId: string;
  readonly shopName: string;
  readonly branchName: string;
  readonly categories: readonly ShopCategory[];
  readonly distanceKm: number;
  readonly area?: string;
  readonly city: string;
  readonly addressLine: string;
  readonly phone: string;
  readonly serviceModes: readonly ServiceMode[];
  /** Whether home service / pickup reaches the searched location. */
  readonly servesYourLocation: boolean;
  readonly isOpenNow: boolean;
  readonly todayHours?: OpeningHoursDay;
  readonly latitude: number;
  readonly longitude: number;
}

export interface ShopDetail extends ShopSearchResult {
  readonly address: ShopAddress;
  readonly openingHours: readonly OpeningHoursDay[];
  readonly serviceRadiusKm: number;
  readonly about?: string;
  readonly directionsUrl: string;
}

export interface ShopSearchPage {
  readonly items: readonly ShopSearchResult[];
  readonly page: number;
  readonly limit: number;
  readonly total: number;
  readonly origin: GeoPoint & { readonly addressId?: string; readonly label?: string };
  readonly radiusKm: number;
}

/** Shown on a new listing until the shop sets its own hours: Mon–Sat 9–8, Sunday closed. */
export const DEFAULT_OPENING_HOURS: readonly OpeningHoursDay[] = [0, 1, 2, 3, 4, 5, 6].map((day) =>
  day === 0 ? { day, closed: true } : { day, closed: false, open: '09:00', close: '20:00' },
);

const DEFAULT_RADIUS_KM = 10;
/** Upper bound of candidates examined per search before in-memory filters and paging. */
const SEARCH_CANDIDATE_LIMIT = 300;
const TRAVELLING_MODES: readonly ServiceMode[] = ['home_service', 'pickup_drop'];

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function missingFieldsOf(listing: {
  readonly address: ShopAddress;
  readonly location?: unknown;
  readonly serviceModes: readonly ServiceMode[];
  readonly openingHours: readonly OpeningHoursDay[];
}): ListingMissingField[] {
  const missing: ListingMissingField[] = [];
  if (!listing.address.streetAddress?.trim()) missing.push('streetAddress');
  if (!listing.address.city?.trim()) missing.push('city');
  if (!listing.address.state?.trim()) missing.push('state');
  if (!/^[1-9]\d{5}$/.test(listing.address.postalCode ?? '')) missing.push('postalCode');
  if (!listing.location) missing.push('location');
  if (listing.serviceModes.length === 0) missing.push('serviceModes');
  if (listing.openingHours.length !== 7 || listing.openingHours.every((day) => day.closed)) {
    missing.push('openingHours');
  }
  return missing;
}

function normalizeOpeningHours(entries: readonly OpeningHoursDto[]): OpeningHoursDay[] {
  const days = new Set(entries.map((entry) => entry.day));
  if (days.size !== 7) {
    throw new BadRequestException('openingHours must have one entry for each day of the week');
  }
  const hours = [...entries]
    .sort((a, b) => a.day - b.day)
    .map((entry): OpeningHoursDay => {
      if (entry.closed) return { day: entry.day, closed: true };
      if (!entry.open || !entry.close || parseClock(entry.open) === parseClock(entry.close)) {
        throw new BadRequestException(
          `Day ${entry.day}: set an opening and a different closing time, or mark it closed`,
        );
      }
      return { day: entry.day, closed: false, open: entry.open, close: entry.close };
    });
  if (hours.every((day) => day.closed)) {
    throw new BadRequestException('The shop must be open on at least one day');
  }
  return hours;
}

function addressLine(address: ShopAddress): string {
  return [address.streetAddress, address.area, address.city].filter(Boolean).join(', ');
}

@Injectable()
export class ListingService {
  constructor(
    private readonly database: MarketplaceDatabase,
    private readonly tenantDirectory: TenantDirectoryClient,
    private readonly addressService: AddressService,
  ) {}

  // ── Shop side ─────────────────────────────────────────────────────────────

  /**
   * The listing for the branch the shop user is signed in to. Before the first
   * save it is a draft pre-filled from the branch address, so the app can show
   * "add your shop address" with the fields already filled in.
   */
  async getForShop(shop: ShopPrincipal): Promise<ShopListingView> {
    const profile = await this.tenantDirectory.getMarketplaceProfile(shop.tenantId);
    const branch = profile.branches.find((candidate) => candidate.branchId === shop.branchId);
    const stored = await this.database.listings
      .findOne({ branchId: shop.branchId, tenantId: shop.tenantId }, { _id: 0 })
      .lean()
      .exec();

    if (stored) {
      // Keep the snapshot in step with tenant-service (name, phone, suspension).
      const refreshed = await this.refreshSnapshot(stored, profile, branch?.branchName);
      return this.toShopView(refreshed);
    }

    const draft = {
      address: {
        streetAddress: branch?.streetAddress ?? '',
        city: branch?.city ?? '',
        state: branch?.state ?? '',
        postalCode: branch?.postalCode ?? '',
      },
      serviceModes: [] as ServiceMode[],
      openingHours: DEFAULT_OPENING_HOURS,
    };
    const missingFields = missingFieldsOf(draft);
    return {
      branchId: shop.branchId,
      tenantId: shop.tenantId,
      shopName: profile.businessName,
      branchName: branch?.branchName ?? '',
      categories: profile.services,
      address: draft.address,
      ownerPhone: profile.ownerPhone,
      phoneShownToCustomers: profile.ownerPhone,
      serviceModes: draft.serviceModes,
      serviceRadiusKm: 5,
      openingHours: draft.openingHours,
      isListed: true,
      saved: false,
      isComplete: false,
      missingFields,
      isVisibleToCustomers: false,
      hiddenReason: 'incomplete',
    };
  }

  async saveForShop(shop: ShopPrincipal, input: UpsertShopListingDto): Promise<ShopListingView> {
    const location = { latitude: input.latitude, longitude: input.longitude };
    if (!isInIndia(location)) {
      throw new BadRequestException('The shop pin must be a location in India');
    }

    let bookingPhone: string | undefined;
    if (input.bookingPhone?.trim()) {
      bookingPhone = normalizeShopPhone(input.bookingPhone);
      if (!bookingPhone) {
        throw new BadRequestException(
          'bookingPhone must be a 10-digit mobile number or a landline with STD code',
        );
      }
    }

    const openingHours = normalizeOpeningHours(input.openingHours);
    const profile = await this.tenantDirectory.getMarketplaceProfile(shop.tenantId);
    const branch = profile.branches.find((candidate) => candidate.branchId === shop.branchId);
    const existing = await this.database.listings
      .findOne({ branchId: shop.branchId }, { tenantId: 1, createdAt: 1 })
      .lean()
      .exec();
    if (existing && existing.tenantId !== shop.tenantId) {
      throw new NotFoundException('Branch not found');
    }

    const now = new Date().toISOString();
    const address: ShopAddress = {
      streetAddress: input.streetAddress.trim(),
      ...(input.area?.trim() ? { area: input.area.trim() } : {}),
      ...(input.landmark?.trim() ? { landmark: input.landmark.trim() } : {}),
      city: input.city.trim(),
      state: input.state.trim(),
      postalCode: input.postalCode,
    };
    const base = {
      address,
      location: toGeoJson(location),
      serviceModes: input.serviceModes,
      openingHours,
    };
    const isComplete = missingFieldsOf(base).length === 0;
    const isListed = input.isListed ?? true;
    const listing: ShopListingDocument = {
      branchId: shop.branchId,
      tenantId: shop.tenantId,
      shopName: profile.businessName,
      branchName: branch?.branchName ?? '',
      categories: profile.services,
      ...base,
      ...(bookingPhone ? { bookingPhone } : {}),
      ownerPhone: profile.ownerPhone,
      serviceRadiusKm: input.serviceRadiusKm ?? 5,
      ...(input.about?.trim() ? { about: input.about.trim() } : {}),
      isListed,
      tenantStatus: profile.status,
      isComplete,
      searchable: isListed && isComplete && profile.status === 'Active',
      updatedBy: shop.actorId,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    };

    // Full replace: cleared optional fields (booking phone, about…) disappear.
    await this.database.listings
      .replaceOne({ branchId: shop.branchId }, listing, { upsert: true })
      .exec();
    return this.toShopView(listing);
  }

  // ── Customer side ─────────────────────────────────────────────────────────

  async search(consumer: ConsumerPrincipal, query: ShopSearchQueryDto): Promise<ShopSearchPage> {
    const origin = await this.resolveOrigin(consumer, query);
    const radiusKm = query.radiusKm ?? DEFAULT_RADIUS_KM;
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;

    const filter: Record<string, unknown> = { searchable: true };
    if (query.category) filter.categories = query.category;
    if (query.mode) filter.serviceModes = query.mode;
    if (query.q?.trim()) filter.shopName = { $regex: escapeRegex(query.q.trim()), $options: 'i' };

    const candidates = await this.database.listings
      .aggregate<ShopListingDocument & { distanceMeters: number }>([
        {
          $geoNear: {
            near: toGeoJson(origin),
            distanceField: 'distanceMeters',
            maxDistance: radiusKm * 1000,
            query: filter,
            spherical: true,
          },
        },
        { $limit: SEARCH_CANDIDATE_LIMIT },
        { $project: { _id: 0 } },
      ])
      .exec();

    const live = await this.tenantDirectory.findSummaries(candidates.map((c) => c.tenantId));
    const now = new Date();
    const results = candidates
      .map((candidate) => this.withLiveTenant(candidate, live))
      .filter(
        (candidate): candidate is ShopListingDocument & { distanceMeters: number } =>
          candidate !== null,
      )
      .map((candidate) => this.toSearchResult(candidate, candidate.distanceMeters, now))
      .filter((result) => !query.openNow || result.isOpenNow)
      // Asking for home service / pickup only makes sense if the shop reaches you.
      .filter(
        (result) =>
          !query.mode || !TRAVELLING_MODES.includes(query.mode) || result.servesYourLocation,
      );

    return {
      items: results.slice((page - 1) * limit, page * limit),
      page,
      limit,
      total: results.length,
      origin,
      radiusKm,
    };
  }

  async detail(
    consumer: ConsumerPrincipal,
    shopId: string,
    query: ShopDetailQueryDto,
  ): Promise<ShopDetail> {
    const stored = await this.database.listings
      .findOne({ branchId: shopId, searchable: true }, { _id: 0 })
      .lean()
      .exec();
    const live = stored ? await this.tenantDirectory.findSummaries([stored.tenantId]) : null;
    const listing = stored ? this.withLiveTenant(stored, live) : null;
    if (!listing?.location) throw new NotFoundException('Shop not found');

    const origin = await this.resolveOrigin(consumer, query);
    const shopPoint = fromGeoJson(listing.location);
    return {
      ...this.toSearchResult(listing, distanceMeters(origin, shopPoint), new Date()),
      address: listing.address,
      openingHours: listing.openingHours,
      serviceRadiusKm: listing.serviceRadiusKm,
      about: listing.about,
      directionsUrl: `https://www.google.com/maps/dir/?api=1&destination=${shopPoint.latitude},${shopPoint.longitude}`,
    };
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  private async resolveOrigin(
    consumer: ConsumerPrincipal,
    query: { addressId?: string; latitude?: number; longitude?: number },
  ): Promise<ShopSearchPage['origin']> {
    if (query.latitude !== undefined || query.longitude !== undefined) {
      if (query.latitude === undefined || query.longitude === undefined) {
        throw new BadRequestException('latitude and longitude must be sent together');
      }
      return { latitude: query.latitude, longitude: query.longitude };
    }
    const address = await this.addressService.resolve(consumer.consumerId, query.addressId);
    return {
      latitude: address.latitude,
      longitude: address.longitude,
      addressId: address.addressId,
      label: address.label,
    };
  }

  /**
   * Applies tenant-service's live name, phone and status. A suspended or
   * deleted business is dropped. If tenant-service is unreachable (live is
   * null) the stored snapshot is used, which was Active when last saved.
   */
  private withLiveTenant<T extends ShopListingDocument>(
    listing: T,
    live: ReadonlyMap<string, TenantSummary> | null,
  ): T | null {
    if (!live) return listing.tenantStatus === 'Active' ? listing : null;
    const tenant = live.get(listing.tenantId);
    if (!tenant || tenant.status !== 'Active') return null;
    return { ...listing, shopName: tenant.businessName, ownerPhone: tenant.ownerPhone };
  }

  private toSearchResult(
    listing: ShopListingDocument,
    meters: number,
    now: Date,
  ): ShopSearchResult {
    const point = fromGeoJson(listing.location!);
    const distanceKm = roundKm(meters);
    return {
      shopId: listing.branchId,
      shopName: listing.shopName,
      branchName: listing.branchName,
      categories: listing.categories,
      distanceKm,
      area: listing.address.area,
      city: listing.address.city,
      addressLine: addressLine(listing.address),
      phone: listing.bookingPhone || listing.ownerPhone,
      serviceModes: listing.serviceModes,
      servesYourLocation:
        listing.serviceModes.some((mode) => TRAVELLING_MODES.includes(mode)) &&
        meters <= listing.serviceRadiusKm * 1000,
      isOpenNow: isOpenAt(listing.openingHours, now),
      todayHours: todayHours(listing.openingHours, now),
      latitude: point.latitude,
      longitude: point.longitude,
    };
  }

  private async refreshSnapshot(
    stored: ShopListingDocument,
    profile: TenantMarketplaceProfile,
    branchName: string | undefined,
  ): Promise<ShopListingDocument> {
    const isComplete = missingFieldsOf(stored).length === 0;
    const next: ShopListingDocument = {
      ...stored,
      shopName: profile.businessName,
      branchName: branchName ?? stored.branchName,
      categories: profile.services,
      ownerPhone: profile.ownerPhone,
      tenantStatus: profile.status,
      isComplete,
      searchable: stored.isListed && isComplete && profile.status === 'Active',
    };
    const changed = (Object.keys(next) as (keyof ShopListingDocument)[]).some(
      (key) => JSON.stringify(next[key]) !== JSON.stringify(stored[key]),
    );
    if (changed) {
      await this.database.listings.replaceOne({ branchId: stored.branchId }, next).exec();
    }
    return next;
  }

  private toShopView(listing: ShopListingDocument): ShopListingView {
    const missingFields = missingFieldsOf(listing);
    const point = listing.location ? fromGeoJson(listing.location) : undefined;
    const hiddenReason =
      missingFields.length > 0
        ? ('incomplete' as const)
        : !listing.isListed
          ? ('unlisted' as const)
          : listing.tenantStatus !== 'Active'
            ? ('business_inactive' as const)
            : undefined;
    return {
      branchId: listing.branchId,
      tenantId: listing.tenantId,
      shopName: listing.shopName,
      branchName: listing.branchName,
      categories: listing.categories,
      address: listing.address,
      latitude: point?.latitude,
      longitude: point?.longitude,
      bookingPhone: listing.bookingPhone,
      ownerPhone: listing.ownerPhone,
      phoneShownToCustomers: listing.bookingPhone || listing.ownerPhone,
      serviceModes: listing.serviceModes,
      serviceRadiusKm: listing.serviceRadiusKm,
      openingHours: listing.openingHours,
      about: listing.about,
      isListed: listing.isListed,
      saved: true,
      isComplete: missingFields.length === 0,
      missingFields,
      isVisibleToCustomers: hiddenReason === undefined,
      hiddenReason,
      updatedAt: listing.updatedAt,
    };
  }
}
