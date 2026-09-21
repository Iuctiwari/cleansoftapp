import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Inject,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { TenantScopedRequest } from '../module-access/module-access.types';
import {
  GOOD_STANDING_SUBSCRIPTION_STATUSES,
  TENANT_SUBSCRIPTION_REPOSITORY,
  type TenantSubscriptionRepository,
} from '../subscription/subscription.types';
import {
  TENANT_SERVICE_BLOCKING_STATUSES,
  TENANT_STATUS_LOOKUP,
  type TenantStatusLookup,
} from './tenant-status.types';

const SAFE_READ_METHODS = new Set(['GET', 'HEAD', 'OPTIONS']);

/**
 * CRITICAL, NON-NEGOTIABLE: defaults to ALLOW when no TenantSubscription
 * record exists, and fails open (ALLOW) whenever the cross-service
 * tenant-service lookup can't produce an answer (not found, or unreachable).
 * Every tenant today has zero TenantSubscription records — a deny-by-default
 * guard here would lock out every existing shop the moment this is wired onto
 * a real route (Phase 6).
 *
 * Enforcement mode: "Read-Only Mode" — a tenant outside good standing (locally
 * or per tenant-service) keeps read access; only write requests are blocked.
 *
 * KILL SWITCH (Phase 6, non-negotiable): checks ENFORCE_TENANT_GUARDS before
 * doing anything else — false (the default) means this guard no-ops and
 * passes every request through, identical to not being wired in at all.
 * Flippable via a pure env var, no code change or redeploy required.
 */
@Injectable()
export class TenantStatusGuard implements CanActivate {
  constructor(
    @Inject(TENANT_SUBSCRIPTION_REPOSITORY)
    private readonly subscriptions: TenantSubscriptionRepository,
    @Inject(TENANT_STATUS_LOOKUP)
    private readonly tenantStatusLookup: TenantStatusLookup,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const enforce = this.configService.get<string>('ENFORCE_TENANT_GUARDS', 'false') === 'true';
    if (!enforce) return true;

    const request = context.switchToHttp().getRequest<TenantScopedRequest>();
    if (!request.tenantId) return true;

    const isWriteRequest = !SAFE_READ_METHODS.has(request.method.toUpperCase());
    if (!isWriteRequest) return true;

    const subscription = await this.subscriptions.findByTenantId(request.tenantId);
    if (subscription && !GOOD_STANDING_SUBSCRIPTION_STATUSES.includes(subscription.status)) {
      throw new ForbiddenException(
        `Tenant subscription status (${subscription.status}) does not allow write operations`,
      );
    }

    const tenantServiceStatus = await this.tenantStatusLookup.getTenantStatus(request.tenantId);
    if (tenantServiceStatus && TENANT_SERVICE_BLOCKING_STATUSES.includes(tenantServiceStatus)) {
      throw new ForbiddenException(
        `Tenant account status (${tenantServiceStatus}) does not allow write operations`,
      );
    }

    return true;
  }
}
