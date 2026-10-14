import type { ConfigService } from '@nestjs/config';

import { OrderBillPushService } from '../src/order/order-bill-push.service';
import type { OrderRecord } from '../src/order/order.types';

const config = {
  get: (key: string, fallback?: string) =>
    ({ INTERNAL_SERVICE_SECRET: 'shh', NOTIFICATION_SERVICE_BASE_URL: 'http://n' })[key] ??
    fallback,
} as unknown as ConfigService;

const item = (service: string, category: string, quantity: number, lineTotal: number) => ({
  itemCategorySnapshot: { name: category },
  lineTotal,
  quantity,
  serviceSnapshot: { name: service },
});

function order(
  customerSnapshot: Record<string, unknown>,
  items = [item('Dry Cleaning', 'Backpack', 1, 260)],
) {
  return {
    customerSnapshot,
    discount: 0,
    grandTotal: 820,
    id: 'o1',
    items,
    orderNumber: 'ORD-1',
  } as unknown as OrderRecord;
}

describe('OrderBillPushService', () => {
  afterEach(() => jest.restoreAllMocks());

  it('pushes the bill to the customer app account', async () => {
    const fetchMock = jest.spyOn(global, 'fetch').mockResolvedValue({ ok: true } as Response);
    new OrderBillPushService(config).sendBill(order({ consumerId: 'c1' }));
    await new Promise((resolve) => setImmediate(resolve));
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe('http://n/api/v1/internal/push');
    const body = JSON.parse((init as RequestInit).body as string);
    expect(body.audience).toEqual({ consumerId: 'c1' });
    expect(body.body).toContain('Dry Cleaning - Backpack x1: Rs. 260');
    expect(body.body).toContain('Total Rs. 820');
  });

  it('does nothing for a customer without the app', () => {
    const fetchMock = jest.spyOn(global, 'fetch');
    new OrderBillPushService(config).sendBill(order({ name: 'Walk-in' }));
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('keeps the total and fits 300 characters for long bills', () => {
    const many = Array.from({ length: 20 }, (_, i) =>
      item('Dry Cleaning', `Item number ${i}`, 1, 100),
    );
    const body = new OrderBillPushService(config).billBody(order({}, many));
    expect(body.length).toBeLessThanOrEqual(300);
    expect(body).toMatch(/\+\d+ more/);
    expect(body.endsWith('Total Rs. 820')).toBe(true);
  });
});
