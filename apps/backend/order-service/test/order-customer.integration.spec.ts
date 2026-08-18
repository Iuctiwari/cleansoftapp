import { BadGatewayException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { HttpOrderDependencies } from '../src/order/order.integrations';
import type { OrderScope } from '../src/order/order.types';

const CUSTOMER_ID = '64f0c18f7c4d2f0012ab34cc';
const TENANT_ID = '64f0c18f7c4d2f0012ab34bb';
const scope: OrderScope = {
  actorId: '64f0c18f7c4d2f0012ab34aa',
  authorization: 'Bearer valid-token',
  branchId: 'branch-a',
  permissions: ['orders:write'],
  roleCode: 'tenant_owner',
  tenantId: TENANT_ID,
};

function response(data: unknown, status = 200): Response {
  return new Response(JSON.stringify({ data }), {
    headers: { 'content-type': 'application/json' },
    status,
  });
}

describe('Order Customer integration', () => {
  const dependencies = new HttpOrderDependencies(
    new ConfigService({ CUSTOMER_SERVICE_BASE_URL: 'http://customer.test' }),
  );
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('fetches a scoped customer and stores only the historical Order snapshot fields', async () => {
    global.fetch = jest.fn().mockResolvedValue(
      response({
        address: 'MG Road',
        branchId: scope.branchId,
        customerType: 'Regular',
        email: 'asha@example.com',
        id: CUSTOMER_ID,
        joiningDate: '2026-01-01T00:00:00.000Z',
        mobile: '+919876543210',
        name: ' Asha Rao ',
        outstandingBalance: 250,
        tenantId: TENANT_ID,
        totalOrders: 12,
        totalSpent: 4000,
      }),
    ) as typeof fetch;

    await expect(dependencies.resolveCustomer(scope, CUSTOMER_ID)).resolves.toEqual({
      address: 'MG Road',
      customerId: CUSTOMER_ID,
      customerType: 'Regular',
      email: 'asha@example.com',
      mobile: '+919876543210',
      name: 'Asha Rao',
    });
    expect(jest.mocked(global.fetch).mock.calls[0]).toEqual([
      `http://customer.test/customers/${CUSTOMER_ID}`,
      {
        headers: {
          authorization: scope.authorization,
          'x-branch-id': scope.branchId,
        },
      },
    ]);
  });

  it('supports the existing walk-in Customer representation without inventing a duplicate', async () => {
    global.fetch = jest.fn().mockResolvedValue(
      response({
        branchId: scope.branchId,
        customerType: 'Walk-in',
        id: CUSTOMER_ID,
        name: 'Walk-in Customer',
        tenantId: TENANT_ID,
      }),
    ) as typeof fetch;

    await expect(dependencies.resolveCustomer(scope, CUSTOMER_ID)).resolves.toEqual({
      customerId: CUSTOMER_ID,
      customerType: 'Walk-in',
      name: 'Walk-in Customer',
    });
  });

  it('rejects a customer returned from another tenant', async () => {
    global.fetch = jest.fn().mockResolvedValue(
      response({
        branchId: scope.branchId,
        customerType: 'Regular',
        id: CUSTOMER_ID,
        name: 'Foreign',
        tenantId: '64f0c18f7c4d2f0012ab3499',
      }),
    ) as typeof fetch;

    await expect(dependencies.resolveCustomer(scope, CUSTOMER_ID)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('rejects a customer returned from another branch', async () => {
    global.fetch = jest.fn().mockResolvedValue(
      response({
        branchId: 'branch-b',
        customerType: 'Regular',
        id: CUSTOMER_ID,
        name: 'Foreign',
        tenantId: TENANT_ID,
      }),
    ) as typeof fetch;

    await expect(dependencies.resolveCustomer(scope, CUSTOMER_ID)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it.each([
    [404, NotFoundException],
    [403, ForbiddenException],
  ])('preserves scoped Customer Service rejection %i', async (status, exception) => {
    global.fetch = jest.fn().mockResolvedValue(response({}, status)) as typeof fetch;

    await expect(dependencies.resolveCustomer(scope, CUSTOMER_ID)).rejects.toBeInstanceOf(
      exception,
    );
  });

  it('maps Customer Service network failure to the centralized gateway exception', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('offline')) as typeof fetch;

    await expect(dependencies.resolveCustomer(scope, CUSTOMER_ID)).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });

  it('rejects malformed Customer Service records instead of persisting them', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValue(
        response({ branchId: scope.branchId, id: CUSTOMER_ID, tenantId: TENANT_ID }),
      ) as typeof fetch;

    await expect(dependencies.resolveCustomer(scope, CUSTOMER_ID)).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });
});
