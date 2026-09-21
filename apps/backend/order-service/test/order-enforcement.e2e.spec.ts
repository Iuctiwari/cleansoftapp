import 'reflect-metadata';

import type { INestApplication, NestMiddleware } from '@nestjs/common';
import { Injectable, Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import type { NextFunction, Request, Response } from 'express';
import request from 'supertest';

import { OrderController } from '../src/order/order.controller';
import type { OrderRequest } from '../src/order/order.guard';
import { OrderScopeGuard } from '../src/order/order.guard';
import { OrderService } from '../src/order/order.service';
import type { OrderScope } from '../src/order/order.types';

/**
 * Phase 6 required verification (2): a genuine end-to-end test of the guard
 * WIRING, not a unit test on OrderEnforcementGuard in isolation. Boots a real
 * Nest HTTP server with the real OrderController/OrderScopeGuard/
 * OrderEnforcementGuard stack and drives it with supertest. The only two
 * things stubbed are (a) the upstream auth call that would normally populate
 * `trustedContext` (replaced by a test-only header, since exercising the real
 * auth-service HTTP call is out of scope for this test) and (b) the outbound
 * fetch to platform-admin-service's internal enforcement endpoint (replaced
 * by a mock keyed on tenantId, so each scenario can deterministically select
 * ACTIVE / SUSPENDED / disabled-module without needing real Mongo state).
 * Live verification against REAL platform-admin-service + real Mongo records
 * is done separately (see this phase's local live-verification step).
 */

const ACTIVE_NO_RECORDS_TENANT = '64f0c18f7c4d2f0012ab3401';
const SUSPENDED_TENANT = '64f0c18f7c4d2f0012ab3402';
const DISABLED_MODULE_TENANT = '64f0c18f7c4d2f0012ab3403';

function scopeFor(tenantId: string): OrderScope {
  return {
    actorId: '64f0c18f7c4d2f0012ab34ff',
    tenantId,
    branchId: 'branch-1',
    roleCode: 'OWNER',
    permissions: ['orders.write'],
    authorization: 'Bearer test-token',
  };
}

@Injectable()
class FakeAuthMiddleware implements NestMiddleware {
  use(req: Request & OrderRequest, _res: Response, next: NextFunction): void {
    const tenantId = req.headers['x-test-tenant-id'];
    if (typeof tenantId === 'string') {
      req.trustedContext = scopeFor(tenantId);
    }
    next();
  }
}

const orderServiceMock = {
  create: jest.fn().mockResolvedValue({ id: 'order-1' }),
  list: jest.fn().mockResolvedValue({ items: [], total: 0 }),
};

function configServiceFor(enforce: boolean): ConfigService {
  const values: Record<string, string> = {
    ENFORCE_TENANT_GUARDS: enforce ? 'true' : 'false',
    PLATFORM_ADMIN_SERVICE_BASE_URL: 'http://localhost:3015/api',
  };
  return { get: (key: string, fallback?: string) => values[key] ?? fallback } as ConfigService;
}

async function bootstrap(enforce: boolean): Promise<INestApplication> {
  @Module({
    controllers: [OrderController],
    providers: [
      OrderScopeGuard,
      { provide: OrderService, useValue: orderServiceMock },
      { provide: ConfigService, useValue: configServiceFor(enforce) },
    ],
  })
  class TestAppModule {
    configure(consumer: import('@nestjs/common').MiddlewareConsumer): void {
      consumer.apply(FakeAuthMiddleware).forRoutes(OrderController);
    }
  }

  const moduleRef = await Test.createTestingModule({ imports: [TestAppModule] }).compile();
  const app = moduleRef.createNestApplication();
  await app.init();
  return app;
}

function httpServer(app: INestApplication): import('http').Server {
  return app.getHttpServer() as import('http').Server;
}

function mockFetchForTenant(tenantId: string): typeof fetch {
  return jest.fn().mockImplementation((url: string) => {
    expect(url).toContain(`/internal/enforcement/${tenantId}`);
    if (tenantId === SUSPENDED_TENANT) {
      return Promise.resolve({
        ok: true,
        json: () =>
          Promise.resolve({
            writeAllowed: false,
            blockedReason: 'Tenant subscription status (SUSPENDED) does not allow write operations',
            disabledModuleKeys: [],
          }),
      });
    }
    if (tenantId === DISABLED_MODULE_TENANT) {
      return Promise.resolve({
        ok: true,
        json: () =>
          Promise.resolve({
            writeAllowed: true,
            disabledModuleKeys: ['ORDER_MANAGEMENT'],
          }),
      });
    }
    // ACTIVE_NO_RECORDS_TENANT: exactly what EnforcementService returns when
    // no TenantSubscription/TenantModuleAccess records exist at all — the
    // default state of every real tenant today.
    return Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ writeAllowed: true, disabledModuleKeys: [] }),
    });
  });
}

describe('Order write-route tenant enforcement (e2e)', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.clearAllMocks();
  });

  describe('ENFORCE_TENANT_GUARDS=false (default)', () => {
    let app: INestApplication;

    beforeAll(async () => {
      app = await bootstrap(false);
    });

    afterAll(async () => {
      await app.close();
    });

    it('allows writes for every tenant regardless of status, and never calls fetch', async () => {
      global.fetch = jest.fn();
      const response = await request(httpServer(app))
        .post('/orders')
        .set('x-test-tenant-id', SUSPENDED_TENANT)
        .send({});
      expect(response.status).toBe(201);
      expect(global.fetch).not.toHaveBeenCalled();
    });
  });

  describe('ENFORCE_TENANT_GUARDS=true', () => {
    let app: INestApplication;

    beforeAll(async () => {
      app = await bootstrap(true);
    });

    afterAll(async () => {
      await app.close();
    });

    it('(a) ACTIVE tenant with no subscription/module records behaves identically to flag-off', async () => {
      global.fetch = mockFetchForTenant(ACTIVE_NO_RECORDS_TENANT);
      const response = await request(httpServer(app))
        .post('/orders')
        .set('x-test-tenant-id', ACTIVE_NO_RECORDS_TENANT)
        .send({});
      expect(response.status).toBe(201);
    });

    it('(b) SUSPENDED tenant is blocked on write routes', async () => {
      global.fetch = mockFetchForTenant(SUSPENDED_TENANT);
      const response = await request(httpServer(app))
        .post('/orders')
        .set('x-test-tenant-id', SUSPENDED_TENANT)
        .send({});
      expect(response.status).toBe(403);
    });

    it('(b) SUSPENDED tenant is still allowed on read routes', async () => {
      global.fetch = mockFetchForTenant(SUSPENDED_TENANT);
      const response = await request(httpServer(app))
        .get('/orders')
        .set('x-test-tenant-id', SUSPENDED_TENANT);
      expect(response.status).toBe(200);
      // GET /orders is never guarded by OrderEnforcementGuard, so the
      // enforcement endpoint is never even called for a read route.
      expect(global.fetch).not.toHaveBeenCalled();
    });

    it('(c) tenant with ORDER_MANAGEMENT disabled is blocked only on that module route', async () => {
      global.fetch = mockFetchForTenant(DISABLED_MODULE_TENANT);
      const writeResponse = await request(httpServer(app))
        .post('/orders')
        .set('x-test-tenant-id', DISABLED_MODULE_TENANT)
        .send({});
      expect(writeResponse.status).toBe(403);

      const readResponse = await request(httpServer(app))
        .get('/orders')
        .set('x-test-tenant-id', DISABLED_MODULE_TENANT);
      expect(readResponse.status).toBe(200);
    });
  });
});
