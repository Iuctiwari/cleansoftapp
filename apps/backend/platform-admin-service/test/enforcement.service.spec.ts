import { ConfigService } from '@nestjs/config';

import { EnforcementService } from '../src/enforcement/enforcement.service';
import { ModuleKey } from '../src/module-access/module-key.enum';
import type {
  TenantModuleAccessRecord,
  TenantModuleAccessRepository,
} from '../src/module-access/module-access.types';
import {
  BillingCycle,
  SubscriptionPlanKey,
  TenantSubscriptionStatus,
  type TenantSubscriptionRecord,
  type TenantSubscriptionRepository,
} from '../src/subscription/subscription.types';
import type { TenantStatusLookup } from '../src/tenant-status/tenant-status.types';

const TENANT_ID = '64f0c18f7c4d2f0012ab3400';

function buildSubscription(
  overrides: Partial<TenantSubscriptionRecord> = {},
): TenantSubscriptionRecord {
  return {
    id: 'sub-1',
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

function buildModuleRecord(
  overrides: Partial<TenantModuleAccessRecord> = {},
): TenantModuleAccessRecord {
  return {
    id: 'mod-1',
    tenantId: TENANT_ID,
    moduleKey: ModuleKey.PAYMENTS,
    isEnabled: false,
    updatedAt: new Date(),
    ...overrides,
  };
}

function buildConfigService(enforce: string): ConfigService {
  return { get: () => enforce } as unknown as ConfigService;
}

describe('EnforcementService', () => {
  function buildService(
    enforce: string,
    subscriptionOverrides: Partial<TenantSubscriptionRepository> = {},
    lookupOverrides: Partial<TenantStatusLookup> = {},
    moduleOverrides: Partial<TenantModuleAccessRepository> = {},
  ): EnforcementService {
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
    const moduleAccess: TenantModuleAccessRepository = {
      findAccess: jest.fn(),
      listForTenant: jest.fn().mockResolvedValue([]),
      setAccess: jest.fn(),
      ...moduleOverrides,
    };
    return new EnforcementService(subscriptions, lookup, moduleAccess, buildConfigService(enforce));
  }

  it('kill switch OFF: reports fully permissive regardless of underlying tenant data', async () => {
    const service = buildService(
      'false',
      {
        findByTenantId: jest
          .fn()
          .mockResolvedValue(buildSubscription({ status: TenantSubscriptionStatus.SUSPENDED })),
      },
      { getTenantStatus: jest.fn().mockResolvedValue('Suspended') },
      { listForTenant: jest.fn().mockResolvedValue([buildModuleRecord({ isEnabled: false })]) },
    );

    const result = await service.getEnforcementStatus(TENANT_ID);
    expect(result).toEqual({ writeAllowed: true, disabledModuleKeys: [] });
  });

  it('kill switch ON, no records anywhere: allows writes, no disabled modules', async () => {
    const service = buildService('true');
    const result = await service.getEnforcementStatus(TENANT_ID);
    expect(result.writeAllowed).toBe(true);
    expect(result.disabledModuleKeys).toEqual([]);
  });

  it('kill switch ON, SUSPENDED subscription: blocks writes with a clear reason', async () => {
    const service = buildService('true', {
      findByTenantId: jest
        .fn()
        .mockResolvedValue(buildSubscription({ status: TenantSubscriptionStatus.SUSPENDED })),
    });

    const result = await service.getEnforcementStatus(TENANT_ID);
    expect(result.writeAllowed).toBe(false);
    expect(result.blockedReason).toContain('SUSPENDED');
  });

  it('kill switch ON, tenant-service reports Suspended: blocks writes with a clear reason', async () => {
    const service = buildService(
      'true',
      {},
      { getTenantStatus: jest.fn().mockResolvedValue('Suspended') },
    );

    const result = await service.getEnforcementStatus(TENANT_ID);
    expect(result.writeAllowed).toBe(false);
    expect(result.blockedReason).toContain('Suspended');
  });

  it('kill switch ON, one disabled module: reports it in disabledModuleKeys, writes still allowed', async () => {
    const service = buildService(
      'true',
      {},
      {},
      {
        listForTenant: jest
          .fn()
          .mockResolvedValue([
            buildModuleRecord({ moduleKey: ModuleKey.PAYMENTS, isEnabled: false }),
            buildModuleRecord({ moduleKey: ModuleKey.EXPENSES, isEnabled: true }),
          ]),
      },
    );

    const result = await service.getEnforcementStatus(TENANT_ID);
    expect(result.writeAllowed).toBe(true);
    expect(result.disabledModuleKeys).toEqual([ModuleKey.PAYMENTS]);
  });
});
