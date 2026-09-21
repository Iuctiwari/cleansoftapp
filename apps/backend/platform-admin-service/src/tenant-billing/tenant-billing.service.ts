import { Injectable } from '@nestjs/common';

import { BillingService, type CreateOrderResult } from '../billing/billing.service';
import { SubscriptionPlanService } from '../subscription/subscription-plan.service';
import type { BillingCycle, SubscriptionPlanRecord } from '../subscription/subscription.types';
import { TenantSubscriptionService } from '../subscription/tenant-subscription.service';
import type { SelectPlanDto } from './dtos/select-plan.dto';
import type {
  TenantPlanSummary,
  TenantSubscriptionStatusResponse,
  TenantSubscriptionSummary,
} from './tenant-billing.types';

const MILLISECONDS_PER_DAY = 24 * 60 * 60 * 1000;

function toPlanSummary(plan: SubscriptionPlanRecord): TenantPlanSummary {
  return {
    planKey: plan.planKey,
    displayName: plan.displayName,
    monthlyPriceInPaise: plan.monthlyPriceInPaise,
    annualPriceInPaise: plan.annualPriceInPaise,
    trialDays: plan.trialDays,
    includedModuleKeys: plan.includedModuleKeys,
    maxBranches: plan.maxBranches,
    maxStaff: plan.maxStaff,
    maxMonthlyOrders: plan.maxMonthlyOrders,
  };
}

function daysRemaining(referenceDate: Date | undefined): number | null {
  if (!referenceDate) return null;
  const diffMs = referenceDate.getTime() - Date.now();
  return Math.ceil(diffMs / MILLISECONDS_PER_DAY);
}

/**
 * Tenant-facing subscription self-service — plan browsing, the tenant's own
 * status, and plan selection/upgrade. Every mutation here is a thin
 * passthrough to the SAME services the Company Admin panel's subscription
 * screens already call (TenantSubscriptionService.assignPlan,
 * BillingService.createOrderForTenant) — this module adds no parallel
 * assignment or billing logic of its own, only tenant-facing shaping/guarding
 * around those existing actions.
 */
@Injectable()
export class TenantBillingService {
  constructor(
    private readonly subscriptionPlanService: SubscriptionPlanService,
    private readonly tenantSubscriptionService: TenantSubscriptionService,
    private readonly billingService: BillingService,
  ) {}

  async listActivePlans(): Promise<readonly TenantPlanSummary[]> {
    const plans = await this.subscriptionPlanService.list();
    return plans.filter((plan) => plan.isActive).map(toPlanSummary);
  }

  async getStatus(tenantId: string): Promise<TenantSubscriptionStatusResponse> {
    const subscription = await this.tenantSubscriptionService.getByTenantId(tenantId);
    if (!subscription) return { hasSubscription: false };

    const plan = await this.subscriptionPlanService.findByPlanKey(subscription.planKey);
    const summary: TenantSubscriptionSummary = {
      autoRenew: subscription.autoRenew,
      billingCycle: subscription.billingCycle,
      daysRemaining: daysRemaining(subscription.endDate ?? subscription.trialEndsAt),
      endDate: subscription.endDate,
      planKey: subscription.planKey,
      startDate: subscription.startDate,
      status: subscription.status,
      trialEndsAt: subscription.trialEndsAt,
    };

    return { hasSubscription: true, plan: toPlanSummary(plan), subscription: summary };
  }

  /**
   * Assigns (or changes to) a plan for this tenant — identical action to the
   * Company Admin panel's "assign plan" button. Never itself triggers
   * billing: onboarding calls this alone (any plan, paid or free — the new
   * Owner is never blocked on payment before their workspace exists), and a
   * post-onboarding plan change additionally calls createOrder afterward
   * only when the newly-assigned plan is paid for the chosen cycle.
   */
  async selectPlan(
    tenantId: string,
    actorUserId: string,
    dto: SelectPlanDto,
  ): Promise<TenantSubscriptionStatusResponse> {
    await this.tenantSubscriptionService.assignPlan(
      tenantId,
      { billingCycle: dto.billingCycle, planKey: dto.planKey },
      actorUserId,
    );
    return this.getStatus(tenantId);
  }

  /**
   * Creates a Razorpay order for the tenant's CURRENTLY assigned plan and
   * billing cycle (same contract as BillingService.createOrderForTenant,
   * which the Company Admin panel's "Create Payment Order" action already
   * uses) — call selectPlan first when switching to a different paid plan,
   * exactly as the admin panel's own two separate actions already require.
   */
  createOrder(tenantId: string, billingCycle?: BillingCycle): Promise<CreateOrderResult> {
    return this.billingService.createOrderForTenant(tenantId, billingCycle);
  }
}
