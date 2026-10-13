import { BadRequestException, ConflictException, ForbiddenException } from '@nestjs/common';

import type { AddressService } from '../src/address/address.service';
import type {
  MarketplaceDatabase,
  ServiceRequestDocument,
  ShopListingDocument,
} from '../src/platform/marketplace.database';
import type { ConsumerPrincipal, ShopPrincipal } from '../src/platform/marketplace.types';
import type { PhotoStorage } from '../src/platform/photo-storage';
import type { PushClient } from '../src/platform/push.client';
import type { ShopServicesClient } from '../src/platform/shop-services.client';
import type { TenantDirectoryClient } from '../src/platform/tenant-directory.client';
import type { CreateServiceRequestDto } from '../src/request/request.dto';
import { istInstant, istToday, RequestService } from '../src/request/request.service';

const consumer: ConsumerPrincipal = {
  consumerId: 'consumer-1',
  displayName: 'Riya Sharma',
  email: 'riya@example.com',
  mobileNumber: '9876543210',
};

const listing: ShopListingDocument = {
  branchId: 'branch-1',
  tenantId: 'tenant-1',
  shopName: 'Sparkle Laundry',
  branchName: 'Head Office',
  categories: ['laundry'],
  address: { streetAddress: 'Shop 4', city: 'Mumbai', state: 'MH', postalCode: '400058' },
  location: { type: 'Point', coordinates: [72.8468, 19.1197] },
  ownerPhone: '9123456789',
  serviceModes: ['visit_shop', 'pickup_drop'],
  serviceRadiusKm: 3,
  // Closed on Sunday (0), open 09:00–20:00 otherwise.
  openingHours: [0, 1, 2, 3, 4, 5, 6].map((day) =>
    day === 0 ? { day, closed: true } : { day, closed: false, open: '09:00', close: '20:00' },
  ),
  isListed: true,
  tenantStatus: 'Active',
  isComplete: true,
  searchable: true,
  updatedBy: 'owner-1',
  createdAt: '2026-10-01T00:00:00.000Z',
  updatedAt: '2026-10-01T00:00:00.000Z',
};

/** Next weekday (Mon–Sat) at least 1 day from today, as YYYY-MM-DD. */
function openDay(): string {
  const date = new Date(`${istToday(new Date())}T00:00:00Z`);
  do date.setUTCDate(date.getUTCDate() + 1);
  while (date.getUTCDay() === 0);
  return date.toISOString().slice(0, 10);
}
function sunday(): string {
  const date = new Date(`${istToday(new Date())}T00:00:00Z`);
  do date.setUTCDate(date.getUTCDate() + 1);
  while (date.getUTCDay() !== 0);
  return date.toISOString().slice(0, 10);
}

function input(overrides: Partial<CreateServiceRequestDto> = {}): CreateServiceRequestDto {
  return {
    shopId: 'branch-1',
    category: 'laundry',
    requestType: 'visit_shop',
    description: 'Wash and iron 5 shirts',
    preferredDate: openDay(),
    preferredSlot: { start: '10:00', end: '12:00' },
    ...overrides,
  };
}

function createSubject(options: { pending?: [number, number]; addressKm?: number } = {}) {
  const created: ServiceRequestDocument[] = [];
  const [pendingHere, pendingTotal] = options.pending ?? [0, 0];
  const counts = [pendingHere, pendingTotal];
  const database = {
    listings: {
      findOne: () => ({ lean: () => ({ exec: () => Promise.resolve(listing) }) }),
    },
    requests: {
      updateMany: () => ({ exec: () => Promise.resolve({ modifiedCount: 0 }) }),
      countDocuments: jest.fn(() => Promise.resolve(counts.shift() ?? 0)),
      create: jest.fn((doc: ServiceRequestDocument) => {
        created.push(doc);
        return Promise.resolve(doc);
      }),
    },
    nextSequence: jest.fn().mockResolvedValue(42),
  } as unknown as MarketplaceDatabase;
  // ~0.011 km per 0.0001° latitude; place the address north of the shop.
  const km = options.addressKm ?? 1;
  const addressService = {
    resolve: jest.fn().mockResolvedValue({
      addressId: 'address-1',
      label: 'Home',
      contactName: 'Riya',
      contactPhone: '9876543210',
      formatted: 'Flat 302, Lokhandwala, Mumbai 400053',
      latitude: 19.1197 + km / 111.2,
      longitude: 72.8468,
    }),
  } as unknown as AddressService;
  const tenantDirectory = {
    findSummaries: jest.fn().mockResolvedValue(
      new Map([
        [
          'tenant-1',
          {
            tenantId: 'tenant-1',
            businessName: 'Sparkle Laundry',
            ownerPhone: '9123456789',
            status: 'Active',
          },
        ],
      ]),
    ),
  } as unknown as TenantDirectoryClient;
  const shopServices = {
    linkOnlineCustomer: jest.fn().mockResolvedValue('crm-customer-1'),
  } as unknown as jest.Mocked<ShopServicesClient>;
  const push = {
    send: jest.fn().mockResolvedValue(undefined),
  } as unknown as jest.Mocked<PushClient>;
  const service = new RequestService(database, addressService, tenantDirectory, shopServices, push, { isEnabled: () => false } as unknown as PhotoStorage);
  return { service, created, shopServices, push };
}

describe('India date helpers', () => {
  it('uses the India calendar date', () => {
    expect(istToday(new Date('2026-10-05T19:00:00Z'))).toBe('2026-10-06'); // 00:30 IST
    expect(istToday(new Date('2026-10-05T18:00:00Z'))).toBe('2026-10-05'); // 23:30 IST
  });

  it('turns a date and India clock time into an instant', () => {
    expect(istInstant('2026-10-08', '10:30')).toBe('2026-10-08T05:00:00.000Z');
  });
});

describe('RequestService.create', () => {
  it('creates a pending request that expires in 48 hours and links the shop customer', async () => {
    const { service, created, shopServices, push } = createSubject();

    const view = await service.create(
      consumer,
      input({ items: [{ name: ' Shirts ', quantity: 5 }] }),
    );

    expect(view).toMatchObject({
      requestNumber: expect.stringMatching(/^SR-\d{4}-000042$/),
      status: 'Pending',
      canCancel: true,
      shop: { shopId: 'branch-1', phone: '9123456789' },
      items: [{ name: 'Shirts', quantity: 5 }],
    });
    const hours = (Date.parse(created[0].expiresAt) - Date.parse(created[0].createdAt)) / 3_600_000;
    expect(hours).toBe(48);
    expect(created[0].shopCustomerId).toBe('crm-customer-1');
    // The shop's phones are told straight away.
    expect(push.send).toHaveBeenCalledWith(
      { tenantId: 'tenant-1', branchId: 'branch-1' },
      'New online request',
      'Riya Sharma · Laundry · Visit shop',
      expect.objectContaining({ type: 'online_request', requestId: expect.any(String) }),
    );
    expect(shopServices.linkOnlineCustomer).toHaveBeenCalledWith('tenant-1', 'branch-1', {
      consumerId: 'consumer-1',
      name: 'Riya Sharma',
      mobile: '9876543210',
      email: 'riya@example.com',
      address: undefined,
    });
    // The customer never sees which staff member did what.
    expect(view.history[0]).not.toHaveProperty('actorId');
  });

  it('still creates the request when the customer list is unreachable', async () => {
    const { service, created, shopServices } = createSubject();
    shopServices.linkOnlineCustomer.mockResolvedValueOnce(undefined);

    await service.create(consumer, input());

    expect(created[0].shopCustomerId).toBeUndefined();
  });

  it.each([
    ['a category the shop does not offer', { category: 'salon' as const }],
    ['a service mode the shop does not offer', { requestType: 'home_service' as const }],
    ['a date in the past', { preferredDate: '2020-01-01' }],
    ['a date more than 30 days ahead', { preferredDate: '2099-01-01' }],
    ['an impossible date', { preferredDate: '2026-02-30' }],
    ['a slot that ends before it starts', { preferredSlot: { start: '12:00', end: '10:00' } }],
    ['a day the shop is closed', { preferredDate: sunday() }],
    ['pickup without an address', { requestType: 'pickup_drop' as const }],
  ])('rejects %s', async (_name, overrides) => {
    const { service, created } = createSubject();
    await expect(service.create(consumer, input(overrides))).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(created).toHaveLength(0);
  });

  it('accepts pickup inside the shop radius and refuses it outside', async () => {
    const inside = createSubject({ addressKm: 2 });
    const outside = createSubject({ addressKm: 5 });
    const pickup = input({ requestType: 'pickup_drop', addressId: 'address-1' });

    const view = await inside.service.create(consumer, pickup);
    await expect(outside.service.create(consumer, pickup)).rejects.toThrow(/serves up to 3 km/);

    expect(view.address).toEqual({
      label: 'Home',
      formatted: 'Flat 302, Lokhandwala, Mumbai 400053',
    });
    expect(inside.created[0].distanceKm).toBe(2);
  });

  it('limits waiting requests per shop and in total', async () => {
    const perShop = createSubject({ pending: [3, 3] });
    const total = createSubject({ pending: [0, 10] });

    await expect(perShop.service.create(consumer, input())).rejects.toBeInstanceOf(
      ConflictException,
    );
    await expect(total.service.create(consumer, input())).rejects.toBeInstanceOf(ConflictException);
  });
});

describe('RequestService shop permissions', () => {
  const shop = (roleCode: string, permissions: string[]): ShopPrincipal => ({
    actorId: 'user-1',
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    roleCode,
    permissions,
    authorization: 'Bearer x',
  });

  it('needs order access to read and order write access to act', async () => {
    const { service } = createSubject();
    const cashier = shop('Cashier', ['process:payments']);

    await expect(service.summaryForShop(cashier)).rejects.toBeInstanceOf(ForbiddenException);
    await expect(service.accept(cashier, 'r1', {})).rejects.toBeInstanceOf(ForbiddenException);
    await expect(
      service.decline(shop('Staff', ['orders:read']), 'r1', { reason: 'busy' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});
