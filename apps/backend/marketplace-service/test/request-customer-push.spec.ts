import type { AddressService } from '../src/address/address.service';
import type {
  MarketplaceDatabase,
  RequestStatus,
  ServiceRequestDocument,
} from '../src/platform/marketplace.database';
import type { ShopPrincipal } from '../src/platform/marketplace.types';
import type { PhotoStorage } from '../src/platform/photo-storage';
import type { PushClient } from '../src/platform/push.client';
import type { ShopServicesClient } from '../src/platform/shop-services.client';
import type { TenantDirectoryClient } from '../src/platform/tenant-directory.client';
import { formatIst, RequestService } from '../src/request/request.service';

const shop: ShopPrincipal = {
  actorId: 'owner-1',
  tenantId: 'tenant-1',
  branchId: 'branch-1',
  roleCode: 'Owner',
  permissions: [],
  authorization: 'Bearer x',
};

function request(overrides: Partial<ServiceRequestDocument> = {}): ServiceRequestDocument {
  return {
    requestId: 'req-1',
    requestNumber: 'SR-2026-000007',
    consumerId: 'consumer-9',
    customer: { name: 'Riya Sharma', mobile: '9876543210', email: 'riya@example.com' },
    tenantId: 'tenant-1',
    branchId: 'branch-1',
    shop: { shopName: 'Sparkle Laundry', branchName: 'Head Office', phone: '9123456789' },
    category: 'laundry',
    requestType: 'visit_shop',
    description: 'Wash and iron',
    items: [],
    preferredDate: '2030-01-08',
    preferredSlot: { start: '10:00', end: '12:00' },
    status: 'Pending',
    shopCustomerId: 'crm-1',
    expiresAt: '2030-01-03T10:00:00.000Z',
    statusHistory: [],
    createdAt: '2030-01-01T10:00:00.000Z',
    updatedAt: '2030-01-01T10:00:00.000Z',
    ...overrides,
  };
}

/** A requests collection where the status change succeeds and returns `after`. */
function createSubject(
  options: { before?: ServiceRequestDocument; after?: ServiceRequestDocument | null } = {},
) {
  const before = options.before ?? request();
  const lean = (value: unknown) => ({ lean: () => ({ exec: () => Promise.resolve(value) }) });
  const database = {
    requests: {
      updateMany: () => ({ exec: () => Promise.resolve({ modifiedCount: 0 }) }),
      findOne: jest.fn(() => lean(before)),
      findOneAndUpdate: jest.fn(() => lean(options.after === undefined ? before : options.after)),
    },
  } as unknown as MarketplaceDatabase;
  const push = {
    send: jest.fn().mockResolvedValue(undefined),
  } as unknown as jest.Mocked<PushClient>;
  const service = new RequestService(
    database,
    {} as AddressService,
    {} as TenantDirectoryClient,
    { linkOnlineCustomer: jest.fn() } as unknown as ShopServicesClient,
    push,
    { isEnabled: () => false } as unknown as PhotoStorage,
  );
  return { service, push };
}

const status = (value: RequestStatus, extra: Partial<ServiceRequestDocument> = {}) =>
  request({ status: value, ...extra });

describe('customer pushes', () => {
  it('tells the customer when the shop accepts, with the confirmed time and note', async () => {
    const { service, push } = createSubject({
      after: status('Accepted', {
        confirmedAt: '2030-01-08T05:00:00.000Z',
        shopNote: 'Please bring the suits by 11',
      }),
    });

    await service.accept(shop, 'req-1', { note: 'Please bring the suits by 11' });

    expect(push.send).toHaveBeenCalledTimes(1);
    expect(push.send).toHaveBeenCalledWith(
      { consumerId: 'consumer-9' },
      'Request accepted',
      `Sparkle Laundry accepted SR-2026-000007 for ${formatIst('2030-01-08T05:00:00.000Z')}. Please bring the suits by 11`,
      { type: 'request_accepted', requestId: 'req-1', requestNumber: 'SR-2026-000007' },
    );
  });

  it('tells the customer why when the shop declines', async () => {
    const { service, push } = createSubject({
      after: status('Declined', { declineReason: 'Fully booked this week' }),
    });

    await service.decline(shop, 'req-1', { reason: 'Fully booked this week' });

    expect(push.send).toHaveBeenCalledWith(
      { consumerId: 'consumer-9' },
      'Request declined',
      'Sparkle Laundry: Fully booked this week',
      expect.objectContaining({ type: 'request_declined', requestId: 'req-1' }),
    );
  });

  it('tells the customer when the request is completed', async () => {
    const { service, push } = createSubject({ after: status('Completed') });

    await service.complete(shop, 'req-1', {});

    expect(push.send).toHaveBeenCalledWith(
      { consumerId: 'consumer-9' },
      'Request completed',
      'Sparkle Laundry marked SR-2026-000007 as completed',
      expect.objectContaining({ type: 'request_completed' }),
    );
  });

  it('does not push when the action did not happen (already handled)', async () => {
    const { service, push } = createSubject({ before: status('Declined'), after: null });

    await expect(service.accept(shop, 'req-1', {})).rejects.toThrow(/already declined/);
    await expect(service.decline(shop, 'req-1', { reason: 'busy now' })).rejects.toThrow();

    expect(push.send).not.toHaveBeenCalled();
  });

  it('a push problem never fails the shop’s action', async () => {
    const { service, push } = createSubject({ after: status('Completed') });
    push.send.mockRejectedValue(new Error('notification-service is down'));

    await expect(service.complete(shop, 'req-1', {})).resolves.toMatchObject({
      status: 'Completed',
    });
  });

  it('writes India time, whatever the server clock', () => {
    expect(formatIst('2030-01-08T05:00:00.000Z')).toBe('Tue, 8 Jan, 10:30 am');
    expect(formatIst('2030-01-08T18:45:00.000Z')).toBe('Wed, 9 Jan, 12:15 am');
  });
});
