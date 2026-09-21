import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type {
  TenantOrderSummary,
  TenantPaymentSummary,
  TenantResourceCounts,
} from './tenant-resource-counts.types';

const REQUEST_TIMEOUT_MS = 3_000;

/**
 * Calls branch-service, user-service, customer-service, order-service, and
 * payment-service's internal endpoints for the Company Admin tenant detail
 * screen. Read-only display data — any failure (network, timeout, non-2xx)
 * degrades that one field to null rather than failing the whole screen; each
 * of the 5 lookups is independent (Promise.all over already-caught
 * sub-promises, never Promise.all over the requests themselves — one slow/
 * down service must never block the other four). Unlike Phase 6's
 * enforcement guard, there is no fail-open/closed SECURITY decision here,
 * just "show what we could get."
 */
@Injectable()
export class TenantResourceCountsService {
  private readonly logger = new Logger(TenantResourceCountsService.name);

  constructor(private readonly configService: ConfigService) {}

  async getCounts(tenantId: string): Promise<TenantResourceCounts> {
    const [branchCount, staffCount, customerCount, orderSummary, paymentSummary] =
      await Promise.all([
        this.fetchJson<{ count?: number }>(
          this.configService.get<string>('BRANCH_SERVICE_BASE_URL', 'http://localhost:3002'),
          `/v1/internal/tenants/${tenantId}/branch-count`,
          'branch-service',
        ).then((body) => body?.count ?? null),
        this.fetchJson<{ count?: number }>(
          this.configService.get<string>('USER_SERVICE_BASE_URL', 'http://localhost:3013/api'),
          `/v1/internal/tenants/${tenantId}/staff-count`,
          'user-service',
        ).then((body) => body?.count ?? null),
        this.fetchJson<{ count?: number }>(
          this.configService.get<string>('CUSTOMER_SERVICE_BASE_URL', 'http://localhost:3003'),
          `/internal/tenants/${tenantId}/customer-count`,
          'customer-service',
        ).then((body) => body?.count ?? null),
        this.fetchJson<TenantOrderSummary>(
          this.configService.get<string>('ORDER_SERVICE_BASE_URL', 'http://localhost:3007/api'),
          `/v1/internal/tenants/${tenantId}/order-summary`,
          'order-service',
        ),
        this.fetchJson<TenantPaymentSummary>(
          this.configService.get<string>('PAYMENT_SERVICE_BASE_URL', 'http://localhost:3010/api'),
          `/v1/internal/tenants/${tenantId}/payment-summary`,
          'payment-service',
        ),
      ]);

    return { branchCount, staffCount, customerCount, orderSummary, paymentSummary };
  }

  private async fetchJson<T>(
    baseUrl: string,
    path: string,
    serviceLabel: string,
  ): Promise<T | null> {
    const sharedSecret = this.configService.get<string>('PLATFORM_ADMIN_INTERNAL_KEY');
    try {
      const response = await fetch(`${baseUrl.replace(/\/$/, '')}${path}`, {
        headers: sharedSecret ? { 'x-platform-admin-key': sharedSecret } : {},
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
      if (!response.ok) {
        this.logger.warn(`[${serviceLabel}] lookup failed: HTTP ${response.status}`);
        return null;
      }
      const body = (await response.json()) as { data?: T } & T;
      return body.data ?? body;
    } catch (error) {
      this.logger.warn(`[${serviceLabel}] lookup failed: ${(error as Error).message}`);
      return null;
    }
  }
}
