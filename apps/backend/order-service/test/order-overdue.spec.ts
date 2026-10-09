import type { ConfigService } from '@nestjs/config';
import type { Model } from 'mongoose';

import { OrderOverdueService } from '../src/order/order-overdue.service';
import type { OrderMongoose } from '../src/order/order.schema';

function createSubject(rows: Array<{ _id: string; count: number }>) {
  const aggregate = jest.fn(() => ({ exec: () => Promise.resolve(rows) }));
  const config = {
    get: (key: string, fallback?: string) =>
      ({ INTERNAL_SERVICE_SECRET: 'shh', NOTIFICATION_SERVICE_BASE_URL: 'http://n' })[key] ??
      fallback,
  } as unknown as ConfigService;
  const service = new OrderOverdueService({ aggregate } as unknown as Model<OrderMongoose>, config);
  return { service, aggregate };
}

describe('OrderOverdueService', () => {
  const fetchMock = jest.fn();
  beforeEach(() => {
    fetchMock.mockReset().mockResolvedValue({ ok: true });
    global.fetch = fetchMock as unknown as typeof fetch;
  });

  it('pushes each shop’s owners once with the count', async () => {
    const { service } = createSubject([
      { _id: 't1', count: 1 },
      { _id: 't2', count: 4 },
    ]);
    await expect(service.alertOwners()).resolves.toEqual({ shops: 2, orders: 5 });
    expect(fetchMock).toHaveBeenCalledTimes(2);
    const body = JSON.parse((fetchMock.mock.calls[1][1] as { body: string }).body);
    expect(body.audience).toEqual({ tenantId: 't2', ownersOnly: true });
    expect(body.body).toBe('4 orders are past the delivery date');
    expect(JSON.parse((fetchMock.mock.calls[0][1] as { body: string }).body).body).toBe(
      '1 order is past the delivery date',
    );
  });

  it('sends nothing when nothing is late, and a push failure never throws', async () => {
    expect(await createSubject([]).service.alertOwners()).toEqual({ shops: 0, orders: 0 });
    expect(fetchMock).not.toHaveBeenCalled();
    fetchMock.mockRejectedValue(new Error('down'));
    await expect(
      createSubject([{ _id: 't1', count: 2 }]).service.alertOwners(),
    ).resolves.toEqual({ shops: 1, orders: 2 });
  });

  it('only accepts the internal secret', () => {
    const { service } = createSubject([]);
    expect(service.isAuthorised('shh')).toBe(true);
    expect(service.isAuthorised('nope')).toBe(false);
    expect(service.isAuthorised(undefined)).toBe(false);
  });
});
