/* eslint-disable @typescript-eslint/unbound-method */
import { NotFoundException } from '@nestjs/common';

import { SubscriptionPlanService } from '../src/subscription/subscription-plan.service';
import { TenantSubscriptionService } from '../src/subscription/tenant-subscription.service';
import {
  BillingCycle,
  SubscriptionHistoryAction,
  SubscriptionPlanKey,
  TenantSubscriptionStatus,
  type SubscriptionHistoryRepository,
  type SubscriptionPlanRecord,
  type TenantSubscriptionRecord,
  type TenantSubscriptionRepository,
} from '../src/subscription/subscription.types';

const TENANT_ID = '64f0c18f7c4d2f0012ab3400';
const ACTOR_ADMIN_ID = '64f0c18f7c4d2f0012ab9000';

function buildPlan(overrides: Partial<SubscriptionPlanRecord> = {}): SubscriptionPlanRecord {
  return {
    id: '64f0c18f7c4d2f0012ab5000',
    planKey: SubscriptionPlanKey.PRO,
    displayName: 'Pro',
    monthlyPriceInPaise: 99900,
    annualPriceInPaise: 999900,
    maxBranches: 5,
    maxStaff: 20,
    maxMonthlyOrders: 5000,
    trialDays: 14,
    includedModuleKeys: [],
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  };
}

function buildSubscription(
  overrides: Partial<TenantSubscriptionRecord> = {},
): TenantSubscriptionRecord {
  return {
    id: '64f0c18f7c4d2f0012ab3777',
    tenantId: TENANT_ID,
    planKey: SubscriptionPlanKey.STARTER,
    status: TenantSubscriptionStatus.TRIALING,
    startDate: new Date('2026-01-01'),
    billingCycle: BillingCycle.MONTHLY,
    autoRenew: false,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

describe('TenantSubscriptionService — SubscriptionHistory audit trail', () => {
  function buildService(
    subscriptionOverrides: Partial<TenantSubscriptionRepository> = {},
    historyOverrides: Partial<SubscriptionHistoryRepository> = {},
  ): { service: TenantSubscriptionService; history: SubscriptionHistoryRepository } {
    const subscriptions: TenantSubscriptionRepository = {
      findByTenantId: jest.fn().mockResolvedValue(null),
      upsert: jest
        .fn()
        .mockImplementation((tenantId: string, input: Partial<TenantSubscriptionRecord>) =>
          Promise.resolve(buildSubscription({ tenantId, ...input })),
        ),
      findManyByTenantIds: jest.fn().mockResolvedValue([]),
      search: jest.fn().mockResolvedValue([]),
      countAllGroupedByPlanKey: jest.fn().mockResolvedValue({}),
      ...subscriptionOverrides,
    };
    const history: SubscriptionHistoryRepository = {
      append: jest
        .fn()
        .mockImplementation((entry) =>
          Promise.resolve({ id: 'history-1', timestamp: new Date(), ...entry }),
        ),
      listByTenantId: jest.fn().mockResolvedValue([]),
      appendIfEventNotProcessed: jest
        .fn()
        .mockImplementation((entry) =>
          Promise.resolve({ id: 'history-1', timestamp: new Date(), ...entry }),
        ),
      ...historyOverrides,
    };

    const planServiceStub = {
      findByPlanKey: jest.fn().mockResolvedValue(buildPlan()),
    } as unknown as SubscriptionPlanService;

    return {
      service: new TenantSubscriptionService(subscriptions, history, planServiceStub),
      history,
    };
  }

  it('(e) writes a PLAN_ASSIGNED history record with correct contents on first plan assignment', async () => {
    const { service, history } = buildService();

    await service.assignPlan(
      TENANT_ID,
      { planKey: SubscriptionPlanKey.PRO, billingCycle: BillingCycle.MONTHLY },
      ACTOR_ADMIN_ID,
    );

    expect(history.append).toHaveBeenCalledTimes(1);
    expect(history.append).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: TENANT_ID,
        action: SubscriptionHistoryAction.PLAN_ASSIGNED,
        previousValue: undefined,
        newValue: { planKey: SubscriptionPlanKey.PRO, billingCycle: BillingCycle.MONTHLY },
        actorAdminUserId: ACTOR_ADMIN_ID,
      }),
    );
  });

  it('(e) writes a PLAN_CHANGED history record with the correct previous/new values on re-assignment', async () => {
    const existing = buildSubscription({
      planKey: SubscriptionPlanKey.STARTER,
      billingCycle: BillingCycle.MONTHLY,
    });
    const { service, history } = buildService({
      findByTenantId: jest.fn().mockResolvedValue(existing),
    });

    await service.assignPlan(
      TENANT_ID,
      { planKey: SubscriptionPlanKey.PRO, billingCycle: BillingCycle.ANNUAL },
      ACTOR_ADMIN_ID,
    );

    expect(history.append).toHaveBeenCalledWith(
      expect.objectContaining({
        action: SubscriptionHistoryAction.PLAN_CHANGED,
        previousValue: { planKey: SubscriptionPlanKey.STARTER, billingCycle: BillingCycle.MONTHLY },
        newValue: { planKey: SubscriptionPlanKey.PRO, billingCycle: BillingCycle.ANNUAL },
      }),
    );
  });

  it('(e) writes a STATUS_CHANGED history record with correct previous/new status', async () => {
    const existing = buildSubscription({ status: TenantSubscriptionStatus.ACTIVE });
    const { service, history } = buildService({
      findByTenantId: jest.fn().mockResolvedValue(existing),
    });

    await service.updateStatus(
      TENANT_ID,
      { status: TenantSubscriptionStatus.SUSPENDED, reason: 'Payment failed 3 times' },
      ACTOR_ADMIN_ID,
    );

    expect(history.append).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: TENANT_ID,
        action: SubscriptionHistoryAction.STATUS_CHANGED,
        previousValue: { status: TenantSubscriptionStatus.ACTIVE },
        newValue: { status: TenantSubscriptionStatus.SUSPENDED },
        actorAdminUserId: ACTOR_ADMIN_ID,
        reason: 'Payment failed 3 times',
      }),
    );
  });

  it('updateStatus throws NotFoundException when the tenant has no subscription yet', async () => {
    const { service } = buildService({ findByTenantId: jest.fn().mockResolvedValue(null) });

    await expect(
      service.updateStatus(TENANT_ID, { status: TenantSubscriptionStatus.ACTIVE }, ACTOR_ADMIN_ID),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('(e) writes an EXTENDED history record with correct previous/new endDate', async () => {
    const existing = buildSubscription({ endDate: new Date('2026-06-01') });
    const { service, history } = buildService({
      findByTenantId: jest.fn().mockResolvedValue(existing),
    });

    await service.extend(
      TENANT_ID,
      { endDate: '2026-12-01', reason: 'Annual renewal' },
      ACTOR_ADMIN_ID,
    );

    expect(history.append).toHaveBeenCalledWith(
      expect.objectContaining({
        action: SubscriptionHistoryAction.EXTENDED,
        previousValue: { endDate: existing.endDate },
        newValue: { endDate: new Date('2026-12-01') },
        reason: 'Annual renewal',
      }),
    );
  });
});
