import { BadRequestException, ConflictException, ForbiddenException } from '@nestjs/common';

import type {
  MarketplaceDatabase,
  SalonBookedPart,
  SalonConfigDocument,
  ServiceRequestDocument,
  ShopListingDocument,
} from '../src/platform/marketplace.database';
import type { ShopPrincipal } from '../src/platform/marketplace.types';
import type { TenantDirectoryClient } from '../src/platform/tenant-directory.client';
import {
  assignParts,
  buildSlots,
  isSlotStart,
  openWindow,
  slotsNeeded,
  type HeldPart,
  type PartNeed,
  type StaffMember,
} from '../src/salon/salon.logic';
import { SalonService } from '../src/salon/salon.service';

const STYLIST: StaffMember = { staffId: 's1', name: 'Asha', role: 'Hair Stylist' };
const STYLIST_2: StaffMember = { staffId: 's2', name: 'Beena', role: 'Hair Stylist' };
const MAKEUP: StaffMember = { staffId: 'm1', name: 'Priya', role: 'Makeup Artist' };

const held = (staffId: string, start: number, end: number, accepted = false): HeldPart => ({
  staffId,
  start,
  end,
  accepted,
});
const cut: PartNeed = { serviceId: 'cut', role: 'Hair Stylist', slots: 1 };
const makeup: PartNeed = { serviceId: 'makeup', role: 'Makeup Artist', slots: 2 };

describe('salon scheduling logic', () => {
  const window = { open: 600, close: 720, slotMinutes: 30 }; // 10:00-12:00

  it('lists every slot as available on an empty day', () => {
    const slots = buildSlots({ ...window, staff: [STYLIST], held: [], needs: [cut] });
    expect(slots.map((slot) => [slot.start, slot.state])).toEqual([
      ['10:00', 'available'],
      ['10:30', 'available'],
      ['11:00', 'available'],
      ['11:30', 'available'],
    ]);
  });

  it('shows pending while a waiting booking holds the only stylist, booked once confirmed', () => {
    const base = { ...window, staff: [STYLIST], needs: [cut] };
    const pending = buildSlots({ ...base, held: [held('s1', 630, 660)] });
    expect(pending[1].state).toBe('pending');
    const booked = buildSlots({ ...base, held: [held('s1', 630, 660, true)] });
    expect(booked[1].state).toBe('booked');
    expect(booked[0].state).toBe('available');
  });

  it('stays available while another person with the same role is free', () => {
    const slots = buildSlots({
      ...window,
      staff: [STYLIST, STYLIST_2],
      held: [held('s1', 600, 630, true)],
      needs: [cut],
    });
    expect(slots[0].state).toBe('available');
  });

  it('gives each service its own worker, one after the other', () => {
    const result = assignParts({
      staff: [STYLIST, MAKEUP],
      held: [],
      needs: [cut, makeup],
      start: 600,
      slotMinutes: 30,
    });
    expect(result).toEqual({
      ok: true,
      parts: [
        { serviceId: 'cut', staffId: 's1', start: 600, end: 630 },
        { serviceId: 'makeup', staffId: 'm1', start: 630, end: 690 },
      ],
    });
  });

  it('fails when one service in the booking has nobody free', () => {
    // The only makeup artist is confirmed 10:30-11:00, inside this booking's makeup part.
    const slots = buildSlots({
      ...window,
      staff: [STYLIST, MAKEUP],
      held: [held('m1', 660, 690, true)],
      needs: [cut, makeup],
    });
    expect(slots.map((slot) => slot.state)).toEqual([
      'booked', // makeup 10:30-11:30 clashes
      'booked', // makeup 11:00-12:00 clashes
      'unavailable', // would run past closing
      'unavailable',
    ]);
  });

  it('marks a service nobody can do as unavailable', () => {
    const slots = buildSlots({ ...window, staff: [STYLIST], held: [], needs: [makeup] });
    expect(slots.every((slot) => slot.state === 'unavailable')).toBe(true);
  });

  it('spreads auto-assigned work to the person with less booked time', () => {
    const result = assignParts({
      staff: [STYLIST, STYLIST_2],
      held: [held('s1', 540, 600, true)],
      needs: [cut],
      start: 600,
      slotMinutes: 30,
    });
    expect(result).toMatchObject({ ok: true, parts: [{ staffId: 's2' }] });
  });

  it('honours the owner pick when that person is free', () => {
    const result = assignParts({
      staff: [STYLIST, STYLIST_2],
      held: [],
      needs: [cut],
      start: 600,
      slotMinutes: 30,
      preferred: { cut: 's2' },
    });
    expect(result).toMatchObject({ ok: true, parts: [{ staffId: 's2' }] });
  });

  it('shows everything available before services are chosen if anyone is free', () => {
    const slots = buildSlots({
      ...window,
      staff: [STYLIST, MAKEUP],
      held: [held('s1', 600, 630, true)],
      needs: [],
    });
    expect(slots[0].state).toBe('available'); // the makeup artist is free
  });

  it('works out the open window, slot starts and slots needed', () => {
    const hours = [
      { day: 0, closed: true },
      { day: 4, closed: false, open: '09:00', close: '18:00' },
    ];
    expect(openWindow(hours, '2026-10-15')).toEqual({ open: 540, close: 1080 }); // Thursday
    expect(openWindow(hours, '2026-10-18')).toBeUndefined(); // Sunday
    expect(isSlotStart(540, 1080, 30, 570)).toBe(true);
    expect(isSlotStart(540, 1080, 30, 575)).toBe(false);
    expect(slotsNeeded(45, 30)).toBe(2);
    expect(slotsNeeded(0, 30)).toBe(1);
  });
});

const BRANCH = 'branch-1';
const DATE = '2026-10-15'; // Thursday
const HOURS = [0, 1, 2, 3, 4, 5, 6].map((day) => ({
  day,
  closed: false,
  open: '10:00',
  close: '14:00',
}));

const baseConfig: SalonConfigDocument = {
  branchId: BRANCH,
  tenantId: 'tenant-1',
  slotMinutes: 30,
  staff: [STYLIST, MAKEUP],
  menu: [
    { serviceId: 'cut', name: 'Haircut', price: 300, durationMinutes: 30, role: 'Hair Stylist' },
    {
      serviceId: 'makeup',
      name: 'Makeup',
      price: 2000,
      durationMinutes: 60,
      role: 'Makeup Artist',
    },
  ],
  updatedBy: 'owner',
  createdAt: '2026-10-01T00:00:00.000Z',
  updatedAt: '2026-10-01T00:00:00.000Z',
};

const listing = {
  branchId: BRANCH,
  tenantId: 'tenant-1',
  shopName: 'Glow Salon',
  categories: ['salon'],
  openingHours: HOURS,
} as unknown as ShopListingDocument;

function part(staff: StaffMember, start: number, end: number, serviceId = 'cut'): SalonBookedPart {
  return {
    serviceId,
    name: serviceId,
    price: 300,
    durationMinutes: end - start,
    role: staff.role,
    staffId: staff.staffId,
    staffName: staff.name,
    startMinute: start,
    endMinute: end,
  };
}

function booking(
  requestId: string,
  parts: SalonBookedPart[],
  status: 'Pending' | 'Accepted' = 'Pending',
  createdAt = '2026-10-10T00:00:00.000Z',
): ServiceRequestDocument {
  return {
    requestId,
    requestNumber: requestId,
    tenantId: 'tenant-1',
    branchId: BRANCH,
    preferredDate: DATE,
    status,
    createdAt,
    expiresAt: '2099-01-01T00:00:00.000Z',
    customer: { name: 'Riya', mobile: '', email: '' },
    salon: {
      parts,
      totalPrice: 300,
      totalMinutes: 30,
      startMinute: parts[0].startMinute,
      endMinute: parts[parts.length - 1].endMinute,
      payment: 'pay_at_shop',
    },
  } as unknown as ServiceRequestDocument;
}

function build(rows: ServiceRequestDocument[], config: Partial<SalonConfigDocument> = {}) {
  const deleted: string[] = [];
  const updates: { filter: unknown; update: unknown }[] = [];
  const stored = { ...baseConfig, ...config };
  const database = {
    salonConfigs: {
      findOne: () => ({ lean: () => ({ exec: () => Promise.resolve(stored) }) }),
    },
    requests: {
      find: () => ({ lean: () => ({ exec: () => Promise.resolve([...rows]) }) }),
      findOne: ({ requestId }: { requestId: string }) => ({
        lean: () => ({
          exec: () => Promise.resolve(rows.find((row) => row.requestId === requestId) ?? null),
        }),
      }),
      deleteOne: ({ requestId }: { requestId: string }) => ({
        exec: () => {
          deleted.push(requestId);
          return Promise.resolve();
        },
      }),
      updateOne: (filter: unknown, update: unknown) => ({
        exec: () => {
          updates.push({ filter, update });
          return Promise.resolve();
        },
      }),
    },
  } as unknown as MarketplaceDatabase;
  const tenants = {
    getMarketplaceProfile: jest.fn().mockResolvedValue({ services: ['salon'] }),
  } as unknown as TenantDirectoryClient;
  return { service: new SalonService(database, tenants), deleted, updates, tenants, stored };
}

const NOW = new Date('2026-10-14T05:00:00.000Z'); // the day before

describe('SalonService.plan', () => {
  it('books a haircut with the stylist and makeup with the makeup artist, one after the other', async () => {
    const { service } = build([]);
    const plan = await service.plan(listing, DATE, '10:00', ['cut', 'makeup'], NOW);
    expect(plan.snapshot).toMatchObject({
      totalPrice: 2300,
      totalMinutes: 90,
      startMinute: 600,
      endMinute: 690,
      payment: 'pay_at_shop',
    });
    expect(
      plan.snapshot.parts.map((p) => [p.name, p.staffName, p.startMinute, p.endMinute]),
    ).toEqual([
      ['Haircut', 'Asha', 600, 630],
      ['Makeup', 'Priya', 630, 690],
    ]);
    expect(plan.slot).toEqual({ start: '10:00', end: '11:30' });
    expect(plan.description).toBe('Haircut, Makeup');
  });

  it('refuses a time when the only person for a service is held by a waiting booking', async () => {
    const { service } = build([booking('a', [part(STYLIST, 600, 630)])]);
    await expect(service.plan(listing, DATE, '10:00', ['cut'], NOW)).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('gives the second customer the other stylist', async () => {
    const { service } = build([booking('a', [part(STYLIST, 600, 630)], 'Accepted')], {
      staff: [STYLIST, STYLIST_2, MAKEUP],
    });
    const plan = await service.plan(listing, DATE, '10:00', ['cut'], NOW);
    expect(plan.snapshot.parts[0].staffName).toBe('Beena');
  });

  it('rejects a service the salon has nobody for', async () => {
    const { service } = build([], { staff: [STYLIST] });
    await expect(service.plan(listing, DATE, '10:00', ['makeup'], NOW)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('rejects off-grid times, unknown services, past slots and late finishes', async () => {
    const { service } = build([]);
    const bad = (start: string, ids: string[], now = NOW) =>
      expect(service.plan(listing, DATE, start, ids, now)).rejects.toBeInstanceOf(
        BadRequestException,
      );
    await bad('10:10', ['cut']);
    await bad('10:00', ['nope']);
    await bad('10:00', []);
    await bad('13:30', ['makeup']);
    await bad('10:30', ['cut'], new Date('2026-10-15T05:30:00.000Z')); // 11:00 India, same day
  });

  it('is not available for a shop that is not a salon', async () => {
    const { service } = build([]);
    const laundry = { ...listing, categories: ['laundry'] } as unknown as ShopListingDocument;
    await expect(service.plan(laundry, DATE, '10:00', ['cut'], NOW)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});

describe('SalonService.settle', () => {
  const mine = booking('mine', [part(STYLIST, 600, 630)], 'Pending', '2026-10-10T00:00:02.000Z');
  const earlier = booking(
    'earlier',
    [part(STYLIST, 600, 630)],
    'Pending',
    '2026-10-10T00:00:01.000Z',
  );

  it('removes the later booking when nobody else can do the service', async () => {
    const { service, deleted, stored } = build([earlier, mine]);
    await expect(service.settle(mine, stored)).rejects.toBeInstanceOf(ConflictException);
    expect(deleted).toEqual(['mine']);
  });

  it('moves the later booking to another person with the same role', async () => {
    const { service, deleted, updates, stored } = build([earlier, mine], {
      staff: [STYLIST, STYLIST_2, MAKEUP],
    });
    await service.settle(mine, { ...stored, staff: [STYLIST, STYLIST_2, MAKEUP] });
    expect(deleted).toEqual([]);
    expect(JSON.stringify(updates[0].update)).toContain('Beena');
  });

  it('keeps a booking that came first', async () => {
    const later = booking(
      'later',
      [part(STYLIST, 600, 630)],
      'Pending',
      '2026-10-10T00:00:03.000Z',
    );
    const { service, deleted, updates, stored } = build([mine, later]);
    await service.settle(mine, stored);
    expect(deleted).toEqual([]);
    expect(updates).toEqual([]);
  });
});

describe('SalonService shop side', () => {
  const shop = (roleCode: string, permissions: string[] = []): ShopPrincipal => ({
    actorId: 'u1',
    tenantId: 'tenant-1',
    branchId: BRANCH,
    roleCode,
    permissions,
    authorization: 'Bearer x',
  });

  it('only lets salon businesses use the salon setup', async () => {
    const { service, tenants } = build([]);
    (tenants.getMarketplaceProfile as jest.Mock).mockResolvedValue({ services: ['laundry'] });
    await expect(service.getConfig(shop('Owner'))).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('keeps team and menu editing to owners and branch managers', async () => {
    const { service } = build([]);
    await expect(
      service.saveConfig(shop('Staff'), { slotMinutes: 30, staff: [], menu: [] }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('refuses a menu service that no one on the team can do', async () => {
    const { service } = build([]);
    await expect(
      service.saveConfig(shop('Owner'), {
        slotMinutes: 30,
        staff: [{ name: 'Asha', role: 'Hair Stylist' }],
        menu: [{ name: 'Facial', price: 500, durationMinutes: 45, role: 'Beautician' }],
      }),
    ).rejects.toThrow('needs a Beautician');
  });

  it('lets the owner swap who does a service, but only to a free person of that role', async () => {
    const rows = [
      booking('a', [part(STYLIST, 600, 630)], 'Pending'),
      booking('b', [part(STYLIST_2, 600, 630)], 'Accepted'),
    ];
    const { service, updates } = build(rows, { staff: [STYLIST, STYLIST_2, MAKEUP] });
    await expect(
      service.assignStaff(shop('Owner'), 'a', {
        assignments: [{ serviceId: 'cut', staffId: 's2' }],
      }),
    ).rejects.toBeInstanceOf(ConflictException); // Beena is busy in 'b'
    await expect(
      service.assignStaff(shop('Owner'), 'a', {
        assignments: [{ serviceId: 'cut', staffId: 'm1' }],
      }),
    ).rejects.toBeInstanceOf(BadRequestException); // wrong role
    expect(updates).toEqual([]);
  });

  it('applies a valid swap', async () => {
    const rows = [booking('a', [part(STYLIST, 600, 630)], 'Pending')];
    const { service, updates } = build(rows, { staff: [STYLIST, STYLIST_2, MAKEUP] });
    const result = await service.assignStaff(shop('Owner'), 'a', {
      assignments: [{ serviceId: 'cut', staffId: 's2' }],
    });
    expect(result.parts[0].staffName).toBe('Beena');
    expect(updates).toHaveLength(1);
  });
});

describe('SalonService.walkIn', () => {
  const owner: ShopPrincipal = {
    actorId: 'owner-1',
    tenantId: 'tenant-1',
    branchId: BRANCH,
    roleCode: 'Owner',
    permissions: [],
    authorization: 'Bearer x',
  };

  function setup(rows: ServiceRequestDocument[], staff = [STYLIST, MAKEUP]) {
    const created: ServiceRequestDocument[] = [];
    const database = {
      salonConfigs: {
        findOne: () => ({
          lean: () => ({ exec: () => Promise.resolve({ ...baseConfig, staff }) }),
        }),
      },
      listings: {
        findOne: () => ({ lean: () => ({ exec: () => Promise.resolve(listing) }) }),
      },
      nextSequence: () => Promise.resolve(7),
      requests: {
        find: () => ({ lean: () => ({ exec: () => Promise.resolve([...rows, ...created]) }) }),
        findOne: ({ requestId }: { requestId: string }) => ({
          lean: () => ({
            exec: () =>
              Promise.resolve(
                [...rows, ...created].find((row) => row.requestId === requestId) ?? null,
              ),
          }),
        }),
        create: (doc: ServiceRequestDocument) => {
          created.push(doc);
          return Promise.resolve();
        },
        deleteOne: () => ({ exec: () => Promise.resolve() }),
        updateOne: () => ({ exec: () => Promise.resolve() }),
      },
    } as unknown as MarketplaceDatabase;
    const tenants = {
      getMarketplaceProfile: jest.fn().mockResolvedValue({ services: ['salon'] }),
    } as unknown as TenantDirectoryClient;
    const shopServices = {
      getCustomer: jest
        .fn()
        .mockResolvedValue({ id: 'c1', name: 'Rohan', mobile: '+919811100001' }),
    };
    return {
      created,
      service: new SalonService(database, tenants, shopServices as never),
      shopServices,
    };
  }

  beforeEach(() => {
    jest.useFakeTimers();
    jest.setSystemTime(new Date('2026-10-15T05:00:00.000Z')); // 10:30 in India, a Thursday
  });
  afterEach(() => jest.useRealTimers());

  it('books the next free slot with the right person and records an accepted walk-in', async () => {
    const { service, created } = setup([]);
    const result = await service.walkIn(owner, { customerId: 'c1', serviceIds: ['cut'] });

    expect(result.parts.map((p) => [p.name, p.staffName, p.startMinute, p.endMinute])).toEqual([
      ['Haircut', 'Asha', 630, 660],
    ]);
    expect(created).toHaveLength(1);
    expect(created[0]).toMatchObject({
      consumerId: 'walk-in:c1',
      shopCustomerId: 'c1',
      status: 'Accepted',
      requestType: 'visit_shop',
      category: 'salon',
      preferredDate: '2026-10-15',
      requestNumber: 'SR-2026-000007',
    });
    expect(created[0].customer.name).toBe('Rohan');
  });

  it('moves to the next slot when the only stylist is busy', async () => {
    const { service } = setup([booking('a', [part(STYLIST, 630, 660)], 'Accepted')]);
    const result = await service.walkIn(owner, { customerId: 'c1', serviceIds: ['cut'] });
    expect(result.parts[0].startMinute).toBe(660);
  });

  it('refuses when nobody can take it for the rest of the day', async () => {
    const { service } = setup([booking('a', [part(STYLIST, 600, 840)], 'Accepted')]);
    await expect(
      service.walkIn(owner, { customerId: 'c1', serviceIds: ['cut'] }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('needs order permission and a salon business', async () => {
    const { service } = setup([]);
    await expect(
      service.walkIn({ ...owner, roleCode: 'Viewer' }, { customerId: 'c1', serviceIds: ['cut'] }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });
});

describe('salon menu price-list links', () => {
  it('are kept on the booked parts so an order can be made from the booking', async () => {
    const linked = {
      ...baseConfig,
      menu: baseConfig.menu.map((item) => ({
        ...item,
        catalogServiceId: `svc-${item.serviceId}`,
        catalogItemCategoryId: `item-${item.serviceId}`,
      })),
    };
    const { service } = build([], linked);
    const plan = await service.plan(listing, DATE, '10:00', ['cut', 'makeup'], NOW);
    expect(plan.snapshot.parts.map((p) => [p.catalogServiceId, p.catalogItemCategoryId])).toEqual([
      ['svc-cut', 'item-cut'],
      ['svc-makeup', 'item-makeup'],
    ]);
  });
});
