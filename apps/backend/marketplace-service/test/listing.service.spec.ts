import { BadRequestException, ForbiddenException } from '@nestjs/common';

import type { AddressService } from '../src/address/address.service';
import type { UpsertShopListingDto } from '../src/listing/listing.dto';
import { DEFAULT_OPENING_HOURS, ListingService } from '../src/listing/listing.service';
import type {
  MarketplaceDatabase,
  ShopListingDocument,
} from '../src/platform/marketplace.database';
import type { ConsumerPrincipal, ShopPrincipal } from '../src/platform/marketplace.types';
import { assertCanEditListing } from '../src/platform/principal.decorators';
import type {
  TenantDirectoryClient,
  TenantMarketplaceProfile,
  TenantSummary,
} from '../src/platform/tenant-directory.client';

const owner: ShopPrincipal = {
  actorId: 'owner-1',
  tenantId: 'tenant-1',
  branchId: 'branch-1',
  roleCode: 'Owner',
  permissions: [],
  authorization: 'Bearer test',
};
const consumer: ConsumerPrincipal = {
  consumerId: 'consumer-1',
  displayName: 'Riya',
  email: 'riya@example.com',
  mobileNumber: '9876543210',
};

function profile(overrides: Partial<TenantMarketplaceProfile> = {}): TenantMarketplaceProfile {
  return {
    tenantId: 'tenant-1',
    businessName: 'Sparkle Laundry',
    businessType: 'laundry',
    ownerName: 'Asha',
    ownerPhone: '9123456789',
    status: 'Active',
    services: ['laundry', 'dry_cleaning'],
    branches: [
      {
        branchId: 'branch-1',
        branchName: 'Head Office',
        streetAddress: 'Shop 4, SV Road',
        city: 'Mumbai',
        state: '',
        postalCode: '400058',
        phone: '9123456789',
        status: 'active',
      },
    ],
    ...overrides,
  };
}

function validInput(overrides: Partial<UpsertShopListingDto> = {}): UpsertShopListingDto {
  return {
    streetAddress: 'Shop 4, SV Road',
    area: 'Andheri West',
    city: 'Mumbai',
    state: 'Maharashtra',
    postalCode: '400058',
    latitude: 19.1197,
    longitude: 72.8468,
    serviceModes: ['visit_shop', 'pickup_drop'],
    serviceRadiusKm: 3,
    openingHours: DEFAULT_OPENING_HOURS.map((day) => ({ ...day })),
    ...overrides,
  };
}

function storedListing(overrides: Partial<ShopListingDocument> = {}): ShopListingDocument {
  return {
    branchId: 'branch-1',
    tenantId: 'tenant-1',
    shopName: 'Old Name',
    branchName: 'Head Office',
    categories: ['laundry'],
    address: {
      streetAddress: 'Shop 4',
      area: 'Andheri West',
      city: 'Mumbai',
      state: 'MH',
      postalCode: '400058',
    },
    location: { type: 'Point', coordinates: [72.8468, 19.1197] },
    ownerPhone: '9000000000',
    serviceModes: ['visit_shop', 'pickup_drop'],
    serviceRadiusKm: 3,
    openingHours: [0, 1, 2, 3, 4, 5, 6].map((day) => ({
      day,
      closed: false,
      open: '00:00',
      close: '23:59',
    })),
    isListed: true,
    tenantStatus: 'Active',
    isComplete: true,
    searchable: true,
    updatedBy: 'owner-1',
    createdAt: '2026-10-01T00:00:00.000Z',
    updatedAt: '2026-10-01T00:00:00.000Z',
    ...overrides,
  };
}

function lean<T>(value: T) {
  return { lean: () => ({ exec: () => Promise.resolve(value) }) };
}

function createSubject(options: {
  stored?: ShopListingDocument | null;
  candidates?: (ShopListingDocument & { distanceMeters: number })[];
  live?: Map<string, TenantSummary> | null;
  tenant?: TenantMarketplaceProfile;
}) {
  const listings = {
    findOne: jest.fn(() => lean(options.stored ?? null)),
    replaceOne: jest.fn((..._args: unknown[]) => ({ exec: () => Promise.resolve({}) })),
    aggregate: jest.fn((..._args: unknown[]) => ({
      exec: () => Promise.resolve(options.candidates ?? []),
    })),
  };
  const database = { listings } as unknown as MarketplaceDatabase;
  const tenantDirectory = {
    getMarketplaceProfile: jest.fn().mockResolvedValue(options.tenant ?? profile()),
    findSummaries: jest
      .fn()
      .mockResolvedValue(options.live === undefined ? new Map() : options.live),
  } as unknown as TenantDirectoryClient;
  const addressService = {
    resolve: jest.fn().mockResolvedValue({
      addressId: 'address-1',
      label: 'Home',
      latitude: 19.1364,
      longitude: 72.8296,
    }),
  } as unknown as AddressService;
  return { service: new ListingService(database, tenantDirectory, addressService), listings };
}

describe('ListingService — shop side', () => {
  it('returns a draft pre-filled from the branch, listing what is still missing', async () => {
    const { service } = createSubject({ stored: null });

    const view = await service.getForShop(owner);

    expect(view.saved).toBe(false);
    expect(view.address).toMatchObject({ streetAddress: 'Shop 4, SV Road', city: 'Mumbai' });
    expect(view.missingFields).toEqual(['state', 'location', 'serviceModes']);
    expect(view.isVisibleToCustomers).toBe(false);
    expect(view.phoneShownToCustomers).toBe('9123456789');
    expect(view.categories).toEqual(['laundry', 'dry_cleaning']);
  });

  it('saves a complete listing as searchable and falls back to the owner phone', async () => {
    const { service, listings } = createSubject({ stored: null });

    const view = await service.saveForShop(owner, validInput({ bookingPhone: '  ' }));

    expect(view).toMatchObject({
      isComplete: true,
      isVisibleToCustomers: true,
      phoneShownToCustomers: '9123456789',
      missingFields: [],
    });
    const saved = listings.replaceOne.mock.calls[0][1] as ShopListingDocument;
    expect(saved.searchable).toBe(true);
    expect(saved.bookingPhone).toBeUndefined();
    expect(saved.location).toEqual({ type: 'Point', coordinates: [72.8468, 19.1197] });
  });

  it('shows the booking phone to customers when one is given', async () => {
    const { service } = createSubject({ stored: null });

    const view = await service.saveForShop(owner, validInput({ bookingPhone: '+91 99887 76655' }));

    expect(view.phoneShownToCustomers).toBe('9988776655');
  });

  it('keeps a suspended business or an unlisted shop hidden', async () => {
    const suspended = createSubject({ stored: null, tenant: profile({ status: 'Suspended' }) });
    const unlisted = createSubject({ stored: null });

    const a = await suspended.service.saveForShop(owner, validInput());
    const b = await unlisted.service.saveForShop(owner, validInput({ isListed: false }));

    expect(a).toMatchObject({ isVisibleToCustomers: false, hiddenReason: 'business_inactive' });
    expect(b).toMatchObject({ isVisibleToCustomers: false, hiddenReason: 'unlisted' });
  });

  it('rejects bad hours, a pin outside India and an invalid booking phone', async () => {
    const { service } = createSubject({ stored: null });
    const allClosed = DEFAULT_OPENING_HOURS.map((day) => ({ day: day.day, closed: true }));
    const duplicateDay = DEFAULT_OPENING_HOURS.map((day) => ({ ...day, day: 1 }));
    const noClose = DEFAULT_OPENING_HOURS.map((day) => ({
      ...day,
      closed: false,
      open: '09:00',
      close: undefined,
    }));

    for (const input of [
      validInput({ openingHours: allClosed }),
      validInput({ openingHours: duplicateDay }),
      validInput({ openingHours: noClose }),
      validInput({ latitude: 0, longitude: 0 }),
      validInput({ bookingPhone: '12345' }),
    ]) {
      await expect(service.saveForShop(owner, input)).rejects.toBeInstanceOf(BadRequestException);
    }
  });

  it('lets only owners and branch managers edit the listing', () => {
    expect(() => assertCanEditListing(owner)).not.toThrow();
    expect(() =>
      assertCanEditListing({
        ...owner,
        roleCode: 'Branch Manager',
        permissions: ['branches:write'],
      }),
    ).not.toThrow();
    expect(() =>
      assertCanEditListing({ ...owner, roleCode: 'Staff', permissions: ['orders:read'] }),
    ).toThrow(ForbiddenException);
  });
});

describe('ListingService — customer search', () => {
  const near = (id: string, meters: number, overrides: Partial<ShopListingDocument> = {}) => ({
    ...storedListing({ branchId: id, tenantId: `tenant-${id}`, ...overrides }),
    distanceMeters: meters,
  });
  const active = (...ids: string[]) =>
    new Map(
      ids.map((id) => [
        `tenant-${id}`,
        {
          tenantId: `tenant-${id}`,
          businessName: `Live ${id}`,
          ownerPhone: '9111111111',
          status: 'Active',
        },
      ]),
    );

  it('keeps MongoDB nearest-first order and uses live name and phone', async () => {
    const { service, listings } = createSubject({
      candidates: [near('a', 800), near('b', 2500, { bookingPhone: '9222222222' })],
      live: active('a', 'b'),
    });

    const page = await service.search(consumer, { category: 'laundry' });

    expect(
      page.items.map((shop) => [shop.shopId, shop.distanceKm, shop.shopName, shop.phone]),
    ).toEqual([
      ['a', 0.8, 'Live a', '9111111111'],
      ['b', 2.5, 'Live b', '9222222222'],
    ]);
    expect(page.origin).toMatchObject({ addressId: 'address-1' });
    const pipeline = listings.aggregate.mock.calls[0][0] as {
      $geoNear?: Record<string, unknown>;
    }[];
    expect(pipeline[0].$geoNear).toMatchObject({
      maxDistance: 10_000,
      query: { searchable: true, categories: 'laundry' },
    });
  });

  it('drops shops whose business is no longer active', async () => {
    const { service } = createSubject({
      candidates: [near('a', 800), near('b', 900)],
      live: active('b'),
    });

    const page = await service.search(consumer, {});

    expect(page.items.map((shop) => shop.shopId)).toEqual(['b']);
  });

  it('falls back to the stored snapshot when tenant-service is down', async () => {
    const { service } = createSubject({
      candidates: [near('a', 800), near('b', 900, { tenantStatus: 'Suspended' })],
      live: null,
    });

    const page = await service.search(consumer, {});

    expect(page.items.map((shop) => [shop.shopId, shop.shopName])).toEqual([['a', 'Old Name']]);
  });

  it('for home service / pickup, only lists shops that reach the customer', async () => {
    const { service } = createSubject({
      candidates: [near('a', 2000), near('b', 4000)], // serviceRadiusKm is 3
      live: active('a', 'b'),
    });

    const pickup = await service.search(consumer, { mode: 'pickup_drop' });
    const visit = await service.search(consumer, { mode: 'visit_shop' });

    expect(pickup.items.map((shop) => shop.shopId)).toEqual(['a']);
    expect(visit.items.map((shop) => shop.shopId)).toEqual(['a', 'b']);
  });

  it('pages results and searches from GPS when given', async () => {
    const { service, listings } = createSubject({
      candidates: [near('a', 100), near('b', 200), near('c', 300)],
      live: active('a', 'b', 'c'),
    });

    const page = await service.search(consumer, {
      latitude: 19.2,
      longitude: 72.9,
      page: 2,
      limit: 2,
    });

    expect(page).toMatchObject({ total: 3, page: 2, limit: 2 });
    expect(page.items.map((shop) => shop.shopId)).toEqual(['c']);
    const pipeline = listings.aggregate.mock.calls[0][0] as { $geoNear?: { near: unknown } }[];
    expect(pipeline[0].$geoNear?.near).toEqual({ type: 'Point', coordinates: [72.9, 19.2] });
  });

  it('rejects half a GPS position', async () => {
    const { service } = createSubject({});
    await expect(service.search(consumer, { latitude: 19.2 })).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});
