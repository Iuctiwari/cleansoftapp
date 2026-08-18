import { BadGatewayException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { HttpOrderDependencies } from '../src/order/order.integrations';
import type { OrderScope } from '../src/order/order.types';

const CATEGORY_ID = '64f0c18f7c4d2f0012ab34dd';
const SERVICE_ID = '64f0c18f7c4d2f0012ab34ee';
const TENANT_ID = '64f0c18f7c4d2f0012ab34bb';
const scope: OrderScope = {
  actorId: '64f0c18f7c4d2f0012ab34aa',
  authorization: 'Bearer valid-token',
  branchId: 'branch-a',
  permissions: ['orders:write'],
  roleCode: 'tenant_owner',
  tenantId: TENANT_ID,
};

function envelope(data: unknown, status = 200): Response {
  return new Response(JSON.stringify({ data }), {
    headers: { 'content-type': 'application/json' },
    status,
  });
}

function catalogFetch(options?: {
  readonly category?: Record<string, unknown>;
  readonly categoryHttpStatus?: number;
  readonly quote?: Record<string, unknown>;
  readonly service?: Record<string, unknown>;
  readonly serviceHttpStatus?: number;
}): typeof fetch {
  const service = {
    branchIds: [scope.branchId],
    code: 'WASH',
    id: SERVICE_ID,
    itemCategoryIds: [CATEGORY_ID],
    pricingType: 'PerItem',
    serviceName: 'Wash',
    status: 'Active',
    tenantId: TENANT_ID,
    ...options?.service,
  };
  const category = {
    code: 'SHIRT',
    id: CATEGORY_ID,
    name: 'Shirt',
    serviceIds: [SERVICE_ID],
    status: 'Active',
    tenantId: TENANT_ID,
    unitType: 'Piece',
    ...options?.category,
  };
  const quote = {
    basePrice: 50,
    branchId: scope.branchId,
    effectiveFrom: '2026-08-01T00:00:00.000Z',
    pricingType: 'PerItem',
    serviceId: SERVICE_ID,
    servicePricingId: '64f0c18f7c4d2f0012ab34ff',
    taxPct: 5,
    version: 3,
    ...options?.quote,
  };

  return jest.fn((input: string | URL | Request) => {
    const url = typeof input === 'string' ? input : input instanceof URL ? input.href : input.url;
    if (url.includes(`/services/${SERVICE_ID}/quote`)) return Promise.resolve(envelope(quote));
    if (url.endsWith(`/services/${SERVICE_ID}`)) {
      return Promise.resolve(envelope(service, options?.serviceHttpStatus));
    }
    if (url.endsWith(`/item-categories/${CATEGORY_ID}`)) {
      return Promise.resolve(envelope(category, options?.categoryHttpStatus));
    }
    return Promise.resolve(envelope({}, 404));
  }) as typeof fetch;
}

describe('Order Catalog integration', () => {
  const dependencies = new HttpOrderDependencies(
    new ConfigService({ SERVICE_SERVICE_BASE_URL: 'http://catalog.test/api/v1' }),
  );
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('validates scoped active references and returns a minimized immutable price snapshot', async () => {
    global.fetch = catalogFetch();

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).resolves.toEqual({
      itemCategorySnapshot: {
        code: 'SHIRT',
        itemCategoryId: CATEGORY_ID,
        name: 'Shirt',
        unitType: 'Piece',
      },
      pricingType: 'PerItem',
      serviceSnapshot: {
        code: 'WASH',
        name: 'Wash',
        pricing: {
          basePrice: 50,
          effectiveFrom: '2026-08-01T00:00:00.000Z',
          pricingType: 'PerItem',
          servicePricingId: '64f0c18f7c4d2f0012ab34ff',
          taxPct: 5,
          version: 3,
        },
        serviceId: SERVICE_ID,
      },
      taxPercent: 5,
      unitPrice: 50,
    });
    expect(global.fetch).toHaveBeenCalledWith(
      `http://catalog.test/api/v1/services/${SERVICE_ID}`,
      expect.any(Object),
    );
    expect(global.fetch).toHaveBeenCalledWith(
      `http://catalog.test/api/v1/item-categories/${CATEGORY_ID}`,
      expect.any(Object),
    );
    expect(global.fetch).toHaveBeenCalledWith(
      `http://catalog.test/api/v1/services/${SERVICE_ID}/quote?branchId=${scope.branchId}&itemCategoryId=${CATEGORY_ID}`,
      expect.any(Object),
    );
  });

  it('rejects inactive services', async () => {
    global.fetch = catalogFetch({ service: { status: 'Inactive' } });

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it.each([
    ['service', { serviceHttpStatus: 404 }],
    ['item category', { categoryHttpStatus: 404 }],
  ])('rejects a missing %s reference', async (_label, options) => {
    global.fetch = catalogFetch(options);

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('rejects inactive item categories', async () => {
    global.fetch = catalogFetch({ category: { status: 'Inactive' } });

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('rejects catalog references from another tenant', async () => {
    global.fetch = catalogFetch({ category: { tenantId: '64f0c18f7c4d2f0012ab3499' } });

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('rejects services unavailable in the authenticated branch', async () => {
    global.fetch = catalogFetch({ service: { branchIds: ['branch-b'] } });

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('rejects invalid item-category/service relationships', async () => {
    global.fetch = catalogFetch({ service: { itemCategoryIds: ['different-category'] } });

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('rejects a quote scoped to another branch', async () => {
    global.fetch = catalogFetch({ quote: { branchId: 'branch-b' } });

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });

  it('maps unavailable Service Management to a gateway exception', async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error('offline')) as typeof fetch;

    await expect(dependencies.quoteCatalog(scope, SERVICE_ID, CATEGORY_ID)).rejects.toBeInstanceOf(
      BadGatewayException,
    );
  });

  it('keeps User/Staff validation deferred without calling a fake external API', async () => {
    global.fetch = jest.fn() as typeof fetch;

    await expect(dependencies.assertStaffEligible(scope, SERVICE_ID)).resolves.toBeUndefined();
    expect(global.fetch).not.toHaveBeenCalled();
  });
});
