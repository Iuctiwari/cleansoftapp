import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import type { CreateOrderResult } from '../billing/billing.service';
import type { TenantConfigRequest } from '../tenant-config/tenant-config.guard-types';
import { CreateTenantOrderDto } from './dtos/create-tenant-order.dto';
import { SelectPlanDto } from './dtos/select-plan.dto';
import { TenantBillingService } from './tenant-billing.service';
import type { TenantPlanSummary, TenantSubscriptionStatusResponse } from './tenant-billing.types';

function requireTenantContext(
  request: TenantConfigRequest,
): NonNullable<TenantConfigRequest['trustedContext']> {
  if (!request.trustedContext) throw new Error('TenantAuthMiddleware was not applied');
  return request.trustedContext;
}

/**
 * Tenant-facing subscription self-service — onboarding's "Choose your plan"
 * step and the in-app Subscription screen. Guarded by TenantAuthMiddleware,
 * the same tenant/staff bearer-token check as TenantConfigController; never
 * PlatformRoleGuard (that's the Company Admin panel's own, separate, guard —
 * see the admin-only TenantSubscriptionController in ../subscription).
 */
@ApiTags('Tenant Subscription')
@Controller('tenant/subscription')
export class TenantBillingController {
  constructor(private readonly tenantBillingService: TenantBillingService) {}

  @Get('plans')
  @ApiOperation({ summary: 'List active subscription plans a tenant can choose from' })
  listPlans(): Promise<readonly TenantPlanSummary[]> {
    return this.tenantBillingService.listActivePlans();
  }

  @Get('status')
  @ApiOperation({ summary: "This tenant's current subscription, plan detail, and days remaining" })
  getStatus(@Req() request: TenantConfigRequest): Promise<TenantSubscriptionStatusResponse> {
    const { tenantId } = requireTenantContext(request);
    return this.tenantBillingService.getStatus(tenantId);
  }

  @Post('select-plan')
  @ApiOperation({
    summary:
      "Assign or change this tenant's plan (never itself billing — see create-order for a paid plan)",
  })
  selectPlan(
    @Req() request: TenantConfigRequest,
    @Body() body: SelectPlanDto,
  ): Promise<TenantSubscriptionStatusResponse> {
    const { actorId, tenantId } = requireTenantContext(request);
    return this.tenantBillingService.selectPlan(tenantId, actorId, body);
  }

  @Post('create-order')
  @ApiOperation({
    summary: 'Create a Razorpay order to pay for the currently-assigned plan/billing cycle',
  })
  createOrder(
    @Req() request: TenantConfigRequest,
    @Body() body: CreateTenantOrderDto,
  ): Promise<CreateOrderResult> {
    const { tenantId } = requireTenantContext(request);
    return this.tenantBillingService.createOrder(tenantId, body.billingCycle);
  }
}
