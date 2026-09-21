/* eslint-disable @typescript-eslint/unbound-method */
import { NotFoundException } from '@nestjs/common';

import { BillingService } from '../src/billing/billing.service';
import type { BillingAttemptRepository } from '../src/billing/billing.types';
import { SubscriptionPlanService } from '../src/subscription/subscription-plan.service';
import { TenantSubscriptionService } from '../src/subscription/tenant-subscription.service';
import {
  BillingCycle,
  SubscriptionPlanKey,
  TenantSubscriptionStatus,
  type SubscriptionPlanRecord,
  type TenantSubscriptionRecord,
} from '../src/subscription/subscription.types';
import type { BillingChargeGateway, CreatedCharge } from '../src/billing/billing.types';

const TENANT_ID = '64f0c18f7c4d2f0012ab3400';

function buildPlan(overrides: Partial<SubscriptionPlanRecord> = {}): SubscriptionPlanRecord {
  return {
    id: 'plan-1',
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
    id: 'sub-1',
    tenantId: TENANT_ID,
    planKey: SubscriptionPlanKey.PRO,
    status: TenantSubscriptionStatus.ACTIVE,
    startDate: new Date('2026-01-01'),
    billingCycle: BillingCycle.MONTHLY,
    autoRenew: false,
    createdAt: new Date('2026-01-01'),
    updatedAt: new Date('2026-01-01'),
    ...overrides,
  };
}

describe('BillingService — create-order amount calculation', () => {
  function buildBillingService(
    subscription: TenantSubscriptionRecord | null,
    plan: SubscriptionPlanRecord,
  ): {
    service: BillingService;
    gateway: BillingChargeGateway;
    billingAttempts: BillingAttemptRepository;
  } {
    const gateway: BillingChargeGateway = {
      createChargeForCycle: jest.fn().mockResolvedValue({
        gatewayOrderId: 'order_test123',
        status: 'created',
      } satisfies CreatedCharge),
    };
    const billingAttempts: BillingAttemptRepository = {
      create: jest
        .fn()
        .mockImplementation((input) => Promise.resolve({ id: 'attempt-1', ...input })),
      findByRazorpayOrderId: jest.fn(),
      markPaid: jest.fn(),
      markFailed: jest.fn(),
      listByTenantId: jest.fn().mockResolvedValue([]),
    };
    const tenantSubscriptionServiceStub = {
      getByTenantId: jest.fn().mockResolvedValue(subscription),
    } as unknown as TenantSubscriptionService;
    const subscriptionPlanServiceStub = {
      findByPlanKey: jest.fn().mockResolvedValue(plan),
    } as unknown as SubscriptionPlanService;

    const service = new BillingService(
      gateway,
      billingAttempts,
      tenantSubscriptionServiceStub,
      subscriptionPlanServiceStub,
    );

    return { service, gateway, billingAttempts };
  }

  it('(e) uses monthlyPriceInPaise when billingCycle is MONTHLY', async () => {
    const plan = buildPlan({ monthlyPriceInPaise: 99900, annualPriceInPaise: 999900 });
    const { service, gateway, billingAttempts } = buildBillingService(
      buildSubscription({ billingCycle: BillingCycle.MONTHLY }),
      plan,
    );

    const result = await service.createOrderForTenant(TENANT_ID);

    expect(result.amountInPaise).toBe(99900);
    expect(gateway.createChargeForCycle).toHaveBeenCalledWith(
      expect.objectContaining({
        amountInPaise: 99900,
        currency: 'INR',
        billingCycle: BillingCycle.MONTHLY,
      }),
    );
    expect(billingAttempts.create).toHaveBeenCalledWith(
      expect.objectContaining({ amountInPaise: 99900, billingCycle: BillingCycle.MONTHLY }),
    );
  });

  it('(e) uses annualPriceInPaise when billingCycle is ANNUAL', async () => {
    const plan = buildPlan({ monthlyPriceInPaise: 99900, annualPriceInPaise: 999900 });
    const { service, gateway } = buildBillingService(
      buildSubscription({ billingCycle: BillingCycle.MONTHLY }),
      plan,
    );

    const result = await service.createOrderForTenant(TENANT_ID, BillingCycle.ANNUAL);

    expect(result.amountInPaise).toBe(999900);
    expect(gateway.createChargeForCycle).toHaveBeenCalledWith(
      expect.objectContaining({ amountInPaise: 999900, billingCycle: BillingCycle.ANNUAL }),
    );
  });

  it("(e) defaults to the subscription's own billingCycle when no override is given", async () => {
    const plan = buildPlan({ monthlyPriceInPaise: 99900, annualPriceInPaise: 999900 });
    const { service } = buildBillingService(
      buildSubscription({ billingCycle: BillingCycle.ANNUAL }),
      plan,
    );

    const result = await service.createOrderForTenant(TENANT_ID);

    expect(result.billingCycle).toBe(BillingCycle.ANNUAL);
    expect(result.amountInPaise).toBe(999900);
  });

  it('throws NotFoundException when the tenant has no subscription to bill', async () => {
    const { service } = buildBillingService(null, buildPlan());

    await expect(service.createOrderForTenant(TENANT_ID)).rejects.toBeInstanceOf(NotFoundException);
  });
});
