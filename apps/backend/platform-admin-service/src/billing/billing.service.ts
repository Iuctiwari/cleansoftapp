import { Inject, Injectable, NotFoundException } from '@nestjs/common';

import { SubscriptionPlanService } from '../subscription/subscription-plan.service';
import { BillingCycle } from '../subscription/subscription.types';
import { TenantSubscriptionService } from '../subscription/tenant-subscription.service';
import { buildReceipt } from './billing.util';
import {
  BILLING_ATTEMPT_REPOSITORY,
  BILLING_CHARGE_GATEWAY,
  type BillingAttemptRecord,
  type BillingAttemptRepository,
  type BillingChargeGateway,
} from './billing.types';

const CURRENCY_INR = 'INR';

export interface CreateOrderResult {
  readonly razorpayOrderId: string;
  readonly amountInPaise: number;
  readonly currency: string;
  readonly billingCycle: BillingCycle;
}

@Injectable()
export class BillingService {
  constructor(
    @Inject(BILLING_CHARGE_GATEWAY) private readonly chargeGateway: BillingChargeGateway,
    @Inject(BILLING_ATTEMPT_REPOSITORY) private readonly billingAttempts: BillingAttemptRepository,
    private readonly tenantSubscriptionService: TenantSubscriptionService,
    private readonly subscriptionPlanService: SubscriptionPlanService,
  ) {}

  async createOrderForTenant(
    tenantId: string,
    billingCycleOverride?: BillingCycle,
  ): Promise<CreateOrderResult> {
    const subscription = await this.tenantSubscriptionService.getByTenantId(tenantId);
    if (!subscription) {
      throw new NotFoundException('Tenant has no subscription to bill — assign a plan first');
    }

    const billingCycle = billingCycleOverride ?? subscription.billingCycle;
    const plan = await this.subscriptionPlanService.findByPlanKey(subscription.planKey);
    const amountInPaise =
      billingCycle === BillingCycle.ANNUAL ? plan.annualPriceInPaise : plan.monthlyPriceInPaise;

    const charge = await this.chargeGateway.createChargeForCycle({
      tenantId,
      amountInPaise,
      currency: CURRENCY_INR,
      billingCycle,
      receipt: buildReceipt(tenantId),
      notes: { tenantId, planKey: subscription.planKey },
    });

    await this.billingAttempts.create({
      tenantId,
      razorpayOrderId: charge.gatewayOrderId,
      amountInPaise,
      currency: CURRENCY_INR,
      billingCycle,
      planKeyAtCreation: subscription.planKey,
    });

    return {
      razorpayOrderId: charge.gatewayOrderId,
      amountInPaise,
      currency: CURRENCY_INR,
      billingCycle,
    };
  }

  listHistory(tenantId: string): Promise<readonly BillingAttemptRecord[]> {
    return this.billingAttempts.listByTenantId(tenantId);
  }
}
