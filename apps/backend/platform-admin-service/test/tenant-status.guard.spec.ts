import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import {
  BillingCycle,
  SubscriptionPlanKey,
  TenantSubscriptionStatus,
  type TenantSubscriptionRecord,
  type TenantSubscriptionRepository,
} from '../src/subscription/subscription.types';
import { TenantStatusGuard } from '../src/tenant-status/tenant-status.guard';
import type { TenantStatusLookup } from '../src/tenant-status/tenant-status.types';

const TENANT_ID = '64f0c18f7c4d2f0012ab3400';

function buildSubscription(
  overrides: Partial<TenantSubscriptionRecord> = {},
): TenantSubscriptionRecord {
  return {
    id: '64f0c18f7c4d2f0012ab3777',
    tenantId: TENANT_ID,
    planKey: SubscriptionPlanKey.PRO,
    status: TenantSubscriptionStatus.ACTIVE,
    startDate: new Date('2026-01-01'),
    billingCycle: BillingCycle.MONTHLY,
    autoRenew: true,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

function buildContext(method: string, tenantId?: string): ExecutionContext {
  const request = { method, tenantId };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => (): void => undefined,
    getClass: () => class {},
  } as unknown as ExecutionContext;
}

function buildConfigService(enforce: string): ConfigService {
  return { get: () => enforce } as unknown as ConfigService;
}

describe('TenantStatusGuard', () => {
  function buildGuard(
    subscriptionOverrides: Partial<TenantSubscriptionRepository> = {},
    lookupOverrides: Partial<TenantStatusLookup> = {},
    enforce = 'true',
  ): TenantStatusGuard {
    const subscriptions: TenantSubscriptionRepository = {
      findByTenantId: jest.fn().mockResolvedValue(null),
      upsert: jest.fn(),
      findManyByTenantIds: jest.fn().mockResolvedValue([]),
      search: jest.fn().mockResolvedValue([]),
      countAllGroupedByPlanKey: jest.fn().mockResolvedValue({}),
      ...subscriptionOverrides,
    };
    const lookup: TenantStatusLookup = {
      getTenantStatus: jest.fn().mockResolvedValue(null),
      ...lookupOverrides,
    };
    return new TenantStatusGuard(subscriptions, lookup, buildConfigService(enforce));
  }

  it('(a) allows a WRITE request for a tenant with ZERO TenantSubscription records (fail-open)', async () => {
    const findByTenantId = jest.fn().mockResolvedValue(null);
    const guard = buildGuard({ findByTenantId });

    const context = buildContext('POST', TENANT_ID);
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(findByTenantId).toHaveBeenCalledWith(TENANT_ID);
  });

  it('always allows READ requests regardless of subscription status', async () => {
    const guard = buildGuard({
      findByTenantId: jest
        .fn()
        .mockResolvedValue(buildSubscription({ status: TenantSubscriptionStatus.SUSPENDED })),
    });

    const context = buildContext('GET', TENANT_ID);
    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  it.each([TenantSubscriptionStatus.EXPIRED, TenantSubscriptionStatus.SUSPENDED])(
    '(c) blocks a WRITE request for a tenant with %s TenantSubscription status',
    async (status) => {
      const guard = buildGuard({
        findByTenantId: jest.fn().mockResolvedValue(buildSubscription({ status })),
      });

      const writeContext = buildContext('PATCH', TENANT_ID);
      await expect(guard.canActivate(writeContext)).rejects.toBeInstanceOf(ForbiddenException);

      const readContext = buildContext('GET', TENANT_ID);
      await expect(guard.canActivate(readContext)).resolves.toBe(true);
    },
  );

  it('allows WRITE requests for TRIALING and ACTIVE subscriptions', async () => {
    for (const status of [TenantSubscriptionStatus.TRIALING, TenantSubscriptionStatus.ACTIVE]) {
      const guard = buildGuard({
        findByTenantId: jest.fn().mockResolvedValue(buildSubscription({ status })),
      });
      await expect(guard.canActivate(buildContext('POST', TENANT_ID))).resolves.toBe(true);
    }
  });

  it('blocks a WRITE request when tenant-service reports the Tenant itself as Suspended', async () => {
    const guard = buildGuard({}, { getTenantStatus: jest.fn().mockResolvedValue('Suspended') });

    await expect(guard.canActivate(buildContext('DELETE', TENANT_ID))).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('fails open when the cross-service tenant-service lookup returns null (not found or unreachable)', async () => {
    const guard = buildGuard({}, { getTenantStatus: jest.fn().mockResolvedValue(null) });

    await expect(guard.canActivate(buildContext('POST', TENANT_ID))).resolves.toBe(true);
  });

  it('fails open when the request has no tenantId', async () => {
    const findByTenantId = jest.fn();
    const guard = buildGuard({ findByTenantId });

    await expect(guard.canActivate(buildContext('POST', undefined))).resolves.toBe(true);
    expect(findByTenantId).not.toHaveBeenCalled();
  });

  describe('kill switch (ENFORCE_TENANT_GUARDS)', () => {
    it.each([TenantSubscriptionStatus.SUSPENDED, TenantSubscriptionStatus.EXPIRED])(
      'with the flag OFF (default), passes a WRITE request even for a %s tenant, and never reads any data',
      async (status) => {
        const findByTenantId = jest.fn().mockResolvedValue(buildSubscription({ status }));
        const getTenantStatus = jest.fn().mockResolvedValue('Suspended');
        const guard = buildGuard({ findByTenantId }, { getTenantStatus }, 'false');

        await expect(guard.canActivate(buildContext('POST', TENANT_ID))).resolves.toBe(true);
        expect(findByTenantId).not.toHaveBeenCalled();
        expect(getTenantStatus).not.toHaveBeenCalled();
      },
    );

    it('with the flag OFF, behaves identically regardless of an unset (undefined) config value too', async () => {
      const guard = new TenantStatusGuard(
        {
          findByTenantId: jest
            .fn()
            .mockResolvedValue(buildSubscription({ status: TenantSubscriptionStatus.SUSPENDED })),
          upsert: jest.fn(),
          findManyByTenantIds: jest.fn().mockResolvedValue([]),
          search: jest.fn().mockResolvedValue([]),
          countAllGroupedByPlanKey: jest.fn().mockResolvedValue({}),
        },
        { getTenantStatus: jest.fn() },
        { get: () => undefined } as unknown as ConfigService,
      );

      await expect(guard.canActivate(buildContext('POST', TENANT_ID))).resolves.toBe(true);
    });

    it('with the flag ON, still enforces normally (regression check for the other tests in this file)', async () => {
      const guard = buildGuard(
        {
          findByTenantId: jest
            .fn()
            .mockResolvedValue(buildSubscription({ status: TenantSubscriptionStatus.SUSPENDED })),
        },
        {},
        'true',
      );

      await expect(guard.canActivate(buildContext('POST', TENANT_ID))).rejects.toBeInstanceOf(
        ForbiddenException,
      );
    });
  });
});
