import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import type { TenantEnforcementResponse } from '@nexoraa/tenant-enforcement-client';

import {
  TENANT_MODULE_ACCESS_REPOSITORY,
  type TenantModuleAccessRepository,
} from '../module-access/module-access.types';
import { ModuleKey } from '../module-access/module-key.enum';
import {
  GOOD_STANDING_SUBSCRIPTION_STATUSES,
  TENANT_SUBSCRIPTION_REPOSITORY,
  type TenantSubscriptionRepository,
} from '../subscription/subscription.types';
import {
  TENANT_SERVICE_BLOCKING_STATUSES,
  TENANT_STATUS_LOOKUP,
  type TenantStatusLookup,
} from '../tenant-status/tenant-status.types';

/**
 * Computes, in ONE place, exactly what TenantStatusGuard + ModuleGuard would
 * decide for a tenant — reusing the SAME repositories those guards use, not
 * a re-derived or duplicated decision. This is what every other service's
 * TenantEnforcementGuard (via @nexoraa/tenant-enforcement-client) calls
 * through the internal HTTP endpoint, combining what would otherwise be two
 * separate guard checks into one round trip.
 */
@Injectable()
export class EnforcementService {
  constructor(
    @Inject(TENANT_SUBSCRIPTION_REPOSITORY)
    private readonly subscriptions: TenantSubscriptionRepository,
    @Inject(TENANT_STATUS_LOOKUP)
    private readonly tenantStatusLookup: TenantStatusLookup,
    @Inject(TENANT_MODULE_ACCESS_REPOSITORY)
    private readonly moduleAccess: TenantModuleAccessRepository,
    private readonly configService: ConfigService,
  ) {}

  async getEnforcementStatus(tenantId: string): Promise<TenantEnforcementResponse> {
    const enforce = this.configService.get<string>('ENFORCE_TENANT_GUARDS', 'false') === 'true';
    if (!enforce) {
      // Defense-in-depth kill switch: even if a caller's OWN flag were
      // somehow on while THIS service's flag is off, report fully permissive.
      // Enforcement requires the flag to be true on both sides, not just one.
      return { writeAllowed: true, disabledModuleKeys: [] };
    }

    let writeAllowed = true;
    let blockedReason: string | undefined;

    const subscription = await this.subscriptions.findByTenantId(tenantId);
    if (subscription && !GOOD_STANDING_SUBSCRIPTION_STATUSES.includes(subscription.status)) {
      writeAllowed = false;
      blockedReason = `Tenant subscription status (${subscription.status}) does not allow write operations`;
    }

    if (writeAllowed) {
      const tenantServiceStatus = await this.tenantStatusLookup.getTenantStatus(tenantId);
      if (tenantServiceStatus && TENANT_SERVICE_BLOCKING_STATUSES.includes(tenantServiceStatus)) {
        writeAllowed = false;
        blockedReason = `Tenant account status (${tenantServiceStatus}) does not allow write operations`;
      }
    }

    const moduleRecords = await this.moduleAccess.listForTenant(tenantId);
    const disabledModuleKeys: ModuleKey[] = moduleRecords
      .filter((record) => !record.isEnabled)
      .map((record) => record.moduleKey);

    return { writeAllowed, blockedReason, disabledModuleKeys };
  }
}
