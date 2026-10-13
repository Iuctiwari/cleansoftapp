import { suggestDelivery } from '../src/request/delivery';
import type {
  MarketplaceDatabase,
  ServiceRequestDocument,
} from '../src/platform/marketplace.database';
import type { ShopPrincipal } from '../src/platform/marketplace.types';
import type { PushClient } from '../src/platform/push.client';
import type { ShopServicesClient } from '../src/platform/shop-services.client';
import type { TenantDirectoryClient } from '../src/request/../platform/tenant-directory.client';
import type { AddressService } from '../src/address/address.service';
import { RequestService } from '../src/request/request.service';

const principal = (roleCode: string, actorId: string, permissions: string[] = []): ShopPrincipal => ({
  actorId,
  tenantId: 't1',
  branchId: 'b1',
  roleCode,
  permissions,
  authorization: 'Bearer x',
});
const owner = principal('Owner', 'owner-1');
const worker = principal('Staff', 'worker-1', ['orders:read', 'orders:write']);

function doc(extra: Partial<ServiceRequestDocument> = {}): ServiceRequestDocument {
  return {
    requestId: 'r1',
    requestNumber: 'SR-1',
    consumerId: 'c1',
    customer: { name: 'Riya', mobile: '9', email: '' },
    tenantId: 't1',
    branchId: 'b1',
    shop: { shopName: 'Sparkle', branchName: 'HO', phone: '1' },
    category: 'laundry',
    requestType: 'pickup_drop',
    description: 'wash',
    items: [],
    preferredDate: '2030-01-08',
    preferredSlot: { start: '10:00', end: '12:00' },
    status: 'Pending',
    expiresAt: '2030-01-10T00:00:00.000Z',
    statusHistory: [],
    createdAt: '2030-01-01T00:00:00.000Z',
    updatedAt: '2030-01-01T00:00:00.000Z',
    ...extra,
  };
}

function subject(current: ServiceRequestDocument) {
  const lean = (v: unknown) => ({ lean: () => ({ exec: () => Promise.resolve(v) }) });
  const findOneAndUpdate = jest.fn((_f: unknown, update: { $set: Partial<ServiceRequestDocument> }) =>
    lean({ ...current, ...update.$set }),
  );
  const database = {
    requests: {
      updateMany: () => ({ exec: () => Promise.resolve({ modifiedCount: 0 }) }),
      findOne: jest.fn(() => lean(current)),
      findOneAndUpdate,
    },
    listings: { findOne: () => lean({ openingHours: [] }) },
  } as unknown as MarketplaceDatabase;
  const push = { send: jest.fn().mockResolvedValue(undefined) } as unknown as jest.Mocked<PushClient>;
  const service = new RequestService(
    database,
    {} as AddressService,
    {} as TenantDirectoryClient,
    { linkOnlineCustomer: jest.fn().mockResolvedValue('crm') } as unknown as ShopServicesClient,
    push,
  );
  return { service, push, findOne: database.requests.findOne as jest.Mock };
}

describe('delivery formula', () => {
  const from = new Date('2030-01-08T06:00:00.000Z'); // Tue, 8 Jan IST
  it('adds a day for each extra batch of items', () => {
    expect(suggestDelivery('laundry', 10, from)).toEqual({ deliveryDate: '2030-01-10', days: 2 });
    expect(suggestDelivery('laundry', 26, from).days).toBe(3);
    expect(suggestDelivery('laundry', 80, from).days).toBe(5);
  });
  it('caps the extra days', () => {
    expect(suggestDelivery('laundry', 5000, from).days).toBe(9);
  });
  it('moves past a closed day', () => {
    const closedThursday = [{ day: 4, closed: true }];
    expect(suggestDelivery('laundry', 10, from, closedThursday).deliveryDate).toBe('2030-01-11');
  });
});

describe('pickup flow', () => {
  it('needs a worker when the shop travels, not for a shop visit', async () => {
    const a = subject(doc());
    await expect(a.service.accept(owner, 'r1', {})).rejects.toThrow(/Choose the worker/);
    const b = subject(doc({ requestType: 'visit_shop' }));
    await expect(b.service.accept(owner, 'r1', {})).resolves.toBeDefined();
  });

  it('accepting with a worker pushes the worker as well as the customer', async () => {
    const { service, push } = subject(doc());
    const view = await service.accept(owner, 'r1', { workerId: 'worker-1', workerName: 'Ravi' });
    expect(view.pickupWorker).toEqual({ userId: 'worker-1', name: 'Ravi' });
    expect(push.send).toHaveBeenCalledWith(
      { userId: 'worker-1' },
      'New pickup for you',
      expect.stringContaining('SR-1'),
      expect.objectContaining({ type: 'pickup_assigned' }),
    );
  });

  it('a worker cannot accept or decline', async () => {
    const { service } = subject(doc());
    await expect(service.accept(worker, 'r1', { workerId: 'worker-1' })).rejects.toThrow(/owner or a branch manager/);
    await expect(service.decline(worker, 'r1', { reason: 'nope' })).rejects.toThrow(/owner or a branch manager/);
  });

  it('a worker only sees pickups sent to them', async () => {
    const { service, findOne } = subject(doc());
    await service.getForShop(worker, 'r1');
    expect(findOne).toHaveBeenCalledWith(
      expect.objectContaining({ 'pickupWorker.userId': 'worker-1' }),
      expect.anything(),
    );
  });

  it('the worker collects, the automatic date is used and the customer is told', async () => {
    const accepted = doc({ status: 'Accepted', pickupWorker: { userId: 'worker-1', name: 'Ravi' } });
    const { service, push } = subject(accepted);
    const view = await service.collect(worker, 'r1', { items: [{ name: 'Shirts', quantity: 12 }, { name: 'Pants', quantity: 8 }] });
    expect(view.collectedItems).toHaveLength(2);
    expect(view.deliveryDateIsCustom).toBe(false);
    expect(view.deliveryDate).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    expect(push.send).toHaveBeenCalledWith(
      { consumerId: 'c1' },
      'Clothes collected',
      expect.stringContaining(view.deliveryDate as string),
      expect.objectContaining({ type: 'request_collected' }),
    );
  });

  it('accepts a custom delivery date but refuses one in the past', async () => {
    const accepted = doc({ status: 'Accepted', pickupWorker: { userId: 'worker-1', name: 'Ravi' } });
    const { service } = subject(accepted);
    await expect(service.collect(worker, 'r1', { items: [{ name: 'a', quantity: 1 }], deliveryDate: '2020-01-01' })).rejects.toThrow(/today up to/);
    const future = new Date(Date.now() + 5 * 86_400_000).toISOString().slice(0, 10);
    const view = await service.collect(worker, 'r1', { items: [{ name: 'a', quantity: 1 }], deliveryDate: future });
    expect(view.deliveryDate).toBe(future);
    expect(view.deliveryDateIsCustom).toBe(true);
  });

  it('refuses a second collection', async () => {
    const done = doc({
      status: 'Accepted',
      pickupWorker: { userId: 'worker-1', name: 'Ravi' },
      collected: { at: 'x', items: [], totalQuantity: 1, byUserId: 'worker-1' },
    });
    await expect(subject(done).service.collect(worker, 'r1', { items: [{ name: 'a', quantity: 1 }] })).rejects.toThrow(/already collected/);
  });
});
