import { BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { Model } from 'mongoose';

import type { PaymentOwnerLookupService } from '../../payment-service/src/payments/payment-owner.service';
import type { PaymentDocument } from '../../payment-service/src/payments/payment.schema';
import { PaymentService } from '../../payment-service/src/payments/payment.service';
import type { PaymentScope } from '../../payment-service/src/payments/payment.types';

// Defaults to "no owner found" so existing recipient-targeted assertions are
// unaffected; owner-notification behavior is covered separately.
const ownerLookup = {
  findOwnerId: jest.fn().mockResolvedValue(undefined),
} as unknown as PaymentOwnerLookupService;

const ORDER_ID = '64f0c18f7c4d2f0012ab34ff';
const CUSTOMER_ID = '64f0c18f7c4d2f0012ab34cc';
const TENANT_ID = '64f0c18f7c4d2f0012ab34bb';
const ACTOR_ID = '64f0c18f7c4d2f0012ab34aa';

const scope: PaymentScope = {
  actorId: ACTOR_ID,
  authorization: 'Bearer token',
  branchId: 'branch-a',
  permissions: ['orders:write'],
  roleCode: 'cashier',
  tenantId: TENANT_ID,
};

function response(data: unknown): Response {
  return new Response(JSON.stringify({ data }), {
    headers: { 'content-type': 'application/json' },
    status: 200,
  });
}

describe('Advance Payment Management', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('persists the selected method in the ledger and applies the protected order projection', async () => {
    const save = jest.fn().mockResolvedValue(undefined);
    const payment = {
      _id: '64f0c18f7c4d2f0012ab3409',
      amountMinor: 2500,
      branchId: scope.branchId,
      currency: 'INR',
      customerId: CUSTOMER_ID,
      idempotencyKey: 'advance-key',
      method: 'Card',
      orderId: ORDER_ID,
      paymentNumber: 'PAY-1',
      paymentType: 'Advance',
      recordedBy: ACTOR_ID,
      save,
      status: 'Pending',
      tenantId: TENANT_ID,
    } as unknown as PaymentDocument;
    const paymentModel = {
      create: jest.fn().mockResolvedValue(payment),
      findOne: jest.fn().mockReturnValue({ exec: jest.fn().mockResolvedValue(null) }),
    };
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce(
        response({
          branchId: scope.branchId,
          customerId: CUSTOMER_ID,
          outstandingAmount: 100,
          tenantId: TENANT_ID,
        }),
      )
      .mockResolvedValueOnce(
        response({
          grandTotal: 100,
          outstandingAmount: 75,
          paidAmount: 25,
          paymentStatus: 'PartiallyPaid',
        }),
      ) as typeof fetch;
    const service = new PaymentService(
      paymentModel as unknown as Model<PaymentDocument>,
      new ConfigService({
        ORDER_SERVICE_BASE_URL: 'http://order.test',
        PAYMENT_PROJECTION_KEY: 'projection-secret',
      }),
      ownerLookup,
    );

    const result = await service.createAdvance(scope, 'advance-key', {
      amountMinor: 2500,
      currency: 'INR',
      customerId: CUSTOMER_ID,
      method: 'Card',
      orderId: ORDER_ID,
      paymentType: 'Advance',
    });

    expect(paymentModel.create).toHaveBeenCalledWith(
      expect.objectContaining({ amountMinor: 2500, method: 'Card', status: 'Pending' }),
    );
    expect(save).toHaveBeenCalledTimes(1);
    expect(result.payment).toEqual(
      expect.objectContaining({ method: 'Card', status: 'Successful' }),
    );
    expect(global.fetch).toHaveBeenLastCalledWith(
      `http://order.test/api/v1/orders/${ORDER_ID}/payment-projection`,
      expect.any(Object),
    );
    const projectionRequest = (global.fetch as jest.MockedFunction<typeof fetch>).mock
      .calls[1]?.[1];
    const projectionHeaders = projectionRequest?.headers as Record<string, string>;
    expect(projectionRequest?.method).toBe('POST');
    expect(projectionHeaders['x-payment-projection-key']).toBe('projection-secret');
  });

  it('rejects an advance above the authoritative outstanding total', async () => {
    const paymentModel = {
      create: jest.fn(),
      findOne: jest.fn().mockReturnValue({ exec: jest.fn().mockResolvedValue(null) }),
    };
    global.fetch = jest.fn().mockResolvedValue(
      response({
        branchId: scope.branchId,
        customerId: CUSTOMER_ID,
        outstandingAmount: 20,
        tenantId: TENANT_ID,
      }),
    ) as typeof fetch;
    const service = new PaymentService(
      paymentModel as unknown as Model<PaymentDocument>,
      new ConfigService({ ORDER_SERVICE_BASE_URL: 'http://order.test' }),
      ownerLookup,
    );

    await expect(
      service.createAdvance(scope, 'too-large', {
        amountMinor: 2500,
        customerId: CUSTOMER_ID,
        method: 'UPI',
        orderId: ORDER_ID,
        paymentType: 'Advance',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
    expect(paymentModel.create).not.toHaveBeenCalled();
  });
});
