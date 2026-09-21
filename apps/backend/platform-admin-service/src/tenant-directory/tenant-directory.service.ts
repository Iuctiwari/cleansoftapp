import { Inject, Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';

import type {
  SubscriptionPlanKey,
  TenantSubscriptionRecord,
  TenantSubscriptionRepository,
  TenantSubscriptionStatus,
} from '../subscription/subscription.types';
import { TENANT_SUBSCRIPTION_REPOSITORY } from '../subscription/subscription.types';
import {
  TENANT_DIRECTORY_REPOSITORY,
  type TenantDirectoryEntry,
  type TenantDirectoryPage,
  type TenantDirectoryQuery,
  type TenantDirectoryRepository,
  type TenantOverviewEntry,
  type TenantOverviewPage,
  type TenantOverviewQuery,
} from './tenant-directory.types';

const DAY_MS = 86_400_000;

@Injectable()
export class TenantDirectoryService {
  private readonly logger = new Logger(TenantDirectoryService.name);

  constructor(
    @Inject(TENANT_DIRECTORY_REPOSITORY) private readonly repository: TenantDirectoryRepository,
    @Inject(TENANT_SUBSCRIPTION_REPOSITORY)
    private readonly subscriptions: TenantSubscriptionRepository,
  ) {}

  async list(query: TenantDirectoryQuery): Promise<TenantDirectoryPage> {
    try {
      return await this.repository.list(query);
    } catch (error) {
      this.logger.error(
        `Tenant directory lookup failed: ${(error as Error).message}`,
        (error as Error).stack,
      );
      throw new ServiceUnavailableException(
        'Unable to reach tenant data right now — try again shortly',
      );
    }
  }

  /**
   * Tenant list enriched with subscription plan/status/days-remaining, for
   * the Company Admin Clients tab and "tenants on this plan" drill-down.
   * Subscription data is this service's own local collection, so when a
   * caller filters by planKey/subscriptionStatus we query it FIRST (to get
   * correct pagination on that filter) and only then fetch matching tenant
   * directory rows — the reverse (paginate tenant-service first, then filter
   * by subscription in memory) would silently under-fill pages. Pragmatic
   * for an internal admin console's realistic tenant counts, not built for
   * tens-of-thousands-of-tenants scale.
   */
  async overview(query: TenantOverviewQuery): Promise<TenantOverviewPage> {
    const page = Math.max(1, query.page ?? 1);
    const limit = Math.min(100, Math.max(1, query.limit ?? 20));

    if (query.tenantId) {
      let directoryEntries: readonly TenantDirectoryEntry[];
      try {
        directoryEntries = await this.repository.listByTenantIds([query.tenantId]);
      } catch (error) {
        this.logger.error(
          `Tenant directory lookup failed: ${(error as Error).message}`,
          (error as Error).stack,
        );
        throw new ServiceUnavailableException(
          'Unable to reach tenant data right now — try again shortly',
        );
      }
      const subscriptions = await this.subscriptions.findManyByTenantIds([query.tenantId]);
      const subscriptionByTenantId = new Map(subscriptions.map((s) => [s.tenantId, s]));
      const items = directoryEntries.map((entry) =>
        this.enrich(entry, subscriptionByTenantId.get(entry.tenantId)),
      );
      return { items, page: 1, limit: items.length, total: items.length };
    }

    if (query.planKey || query.subscriptionStatus) {
      const subscriptions = await this.subscriptions.search({
        planKey: query.planKey as SubscriptionPlanKey | undefined,
        status: query.subscriptionStatus as TenantSubscriptionStatus | undefined,
      });
      const subscriptionByTenantId = new Map(subscriptions.map((s) => [s.tenantId, s]));
      const tenantIds = subscriptions.map((s) => s.tenantId);
      let directoryEntries: readonly TenantDirectoryEntry[];
      try {
        directoryEntries = await this.repository.listByTenantIds(tenantIds);
      } catch (error) {
        this.logger.error(
          `Tenant directory lookup failed: ${(error as Error).message}`,
          (error as Error).stack,
        );
        throw new ServiceUnavailableException(
          'Unable to reach tenant data right now — try again shortly',
        );
      }

      let merged = directoryEntries.map((entry) =>
        this.enrich(entry, subscriptionByTenantId.get(entry.tenantId)),
      );

      if (query.search) {
        const needle = query.search.toLowerCase();
        merged = merged.filter(
          (entry) =>
            entry.businessName.toLowerCase().includes(needle) ||
            entry.ownerName.toLowerCase().includes(needle) ||
            entry.ownerEmail.toLowerCase().includes(needle),
        );
      }
      if (query.onboardingStatus) {
        merged = merged.filter((entry) => entry.status === query.onboardingStatus);
      }

      const total = merged.length;
      const start = (page - 1) * limit;
      return { items: merged.slice(start, start + limit), page, limit, total };
    }

    const directoryPage = await this.list({
      search: query.search,
      status: query.onboardingStatus,
      page,
      limit,
    });
    const subscriptions = await this.subscriptions.findManyByTenantIds(
      directoryPage.items.map((entry) => entry.tenantId),
    );
    const subscriptionByTenantId = new Map(subscriptions.map((s) => [s.tenantId, s]));
    return {
      ...directoryPage,
      items: directoryPage.items.map((entry) =>
        this.enrich(entry, subscriptionByTenantId.get(entry.tenantId)),
      ),
    };
  }

  private enrich(
    entry: TenantDirectoryEntry,
    subscription: TenantSubscriptionRecord | undefined,
  ): TenantOverviewEntry {
    if (!subscription) {
      return { ...entry, planKey: undefined, subscriptionStatus: undefined, daysRemaining: null };
    }
    const relevantDate = subscription.endDate ?? subscription.trialEndsAt;
    const daysRemaining = relevantDate
      ? Math.ceil((relevantDate.getTime() - Date.now()) / DAY_MS)
      : null;
    return {
      ...entry,
      planKey: subscription.planKey,
      subscriptionStatus: subscription.status,
      daysRemaining,
    };
  }
}
