import { Inject, Injectable, NotFoundException } from '@nestjs/common';

import { SubscriptionPlanService } from './subscription-plan.service';
import {
  SUBSCRIPTION_HISTORY_REPOSITORY,
  SubscriptionHistoryAction,
  TENANT_SUBSCRIPTION_REPOSITORY,
  TenantSubscriptionStatus,
  type SubscriptionHistoryRecord,
  type SubscriptionHistoryRepository,
  type TenantSubscriptionRecord,
  type TenantSubscriptionRepository,
} from './subscription.types';
import type { AssignPlanDto } from './dtos/assign-plan.dto';
import type { ExtendSubscriptionDto } from './dtos/extend-subscription.dto';
import type { UpdateSubscriptionStatusDto } from './dtos/update-status.dto';

@Injectable()
export class TenantSubscriptionService {
  constructor(
    @Inject(TENANT_SUBSCRIPTION_REPOSITORY)
    private readonly subscriptions: TenantSubscriptionRepository,
    @Inject(SUBSCRIPTION_HISTORY_REPOSITORY)
    private readonly history: SubscriptionHistoryRepository,
    private readonly subscriptionPlanService: SubscriptionPlanService,
  ) {}

  getByTenantId(tenantId: string): Promise<TenantSubscriptionRecord | null> {
    return this.subscriptions.findByTenantId(tenantId);
  }

  async assignPlan(
    tenantId: string,
    dto: AssignPlanDto,
    actorAdminUserId: string,
  ): Promise<TenantSubscriptionRecord> {
    const plan = await this.subscriptionPlanService.findByPlanKey(dto.planKey);
    const existing = await this.subscriptions.findByTenantId(tenantId);

    // A plan's trialDays only means something the first time it's assigned —
    // once trialEndsAt exists (or the caller sets one explicitly), that value
    // wins, so changing plans later never silently resets an in-progress trial.
    const trialEndsAt = dto.trialEndsAt
      ? new Date(dto.trialEndsAt)
      : (existing?.trialEndsAt ??
        (plan.trialDays > 0
          ? new Date(Date.now() + plan.trialDays * 24 * 60 * 60 * 1000)
          : undefined));

    const updated = await this.subscriptions.upsert(tenantId, {
      planKey: dto.planKey,
      status: existing?.status ?? TenantSubscriptionStatus.TRIALING,
      startDate: existing?.startDate ?? new Date(),
      endDate: dto.endDate ? new Date(dto.endDate) : existing?.endDate,
      trialEndsAt,
      branchLimit: dto.branchLimit ?? plan.maxBranches,
      staffLimit: dto.staffLimit ?? plan.maxStaff,
      monthlyOrderLimit: dto.monthlyOrderLimit ?? plan.maxMonthlyOrders,
      billingCycle: dto.billingCycle,
      autoRenew: dto.autoRenew ?? existing?.autoRenew ?? false,
      notes: dto.notes ?? existing?.notes,
      updatedByAdminUserId: actorAdminUserId,
    });

    await this.history.append({
      tenantId,
      action: existing
        ? SubscriptionHistoryAction.PLAN_CHANGED
        : SubscriptionHistoryAction.PLAN_ASSIGNED,
      previousValue: existing
        ? { planKey: existing.planKey, billingCycle: existing.billingCycle }
        : undefined,
      newValue: { planKey: updated.planKey, billingCycle: updated.billingCycle },
      actorAdminUserId,
      reason: dto.notes,
    });

    return updated;
  }

  async updateStatus(
    tenantId: string,
    dto: UpdateSubscriptionStatusDto,
    actorAdminUserId: string,
  ): Promise<TenantSubscriptionRecord> {
    const existing = await this.subscriptions.findByTenantId(tenantId);
    if (!existing) throw new NotFoundException('Tenant has no subscription to update');

    const updated = await this.subscriptions.upsert(tenantId, {
      status: dto.status,
      updatedByAdminUserId: actorAdminUserId,
    });

    await this.history.append({
      tenantId,
      action: SubscriptionHistoryAction.STATUS_CHANGED,
      previousValue: { status: existing.status },
      newValue: { status: dto.status },
      actorAdminUserId,
      reason: dto.reason,
    });

    return updated;
  }

  async extend(
    tenantId: string,
    dto: ExtendSubscriptionDto,
    actorAdminUserId: string,
  ): Promise<TenantSubscriptionRecord> {
    const existing = await this.subscriptions.findByTenantId(tenantId);
    if (!existing) throw new NotFoundException('Tenant has no subscription to extend');

    const newEndDate = new Date(dto.endDate);
    const updated = await this.subscriptions.upsert(tenantId, {
      endDate: newEndDate,
      updatedByAdminUserId: actorAdminUserId,
    });

    await this.history.append({
      tenantId,
      action: SubscriptionHistoryAction.EXTENDED,
      previousValue: { endDate: existing.endDate ?? null },
      newValue: { endDate: newEndDate },
      actorAdminUserId,
      reason: dto.reason,
    });

    return updated;
  }

  listHistory(tenantId: string): Promise<readonly SubscriptionHistoryRecord[]> {
    return this.history.listByTenantId(tenantId);
  }
}
