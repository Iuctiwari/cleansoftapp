import { Injectable, Logger, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { ShopCategory } from './marketplace.types';

const REQUEST_TIMEOUT_MS = 5_000;

export interface TenantBranch {
  readonly branchId: string;
  readonly branchName: string;
  readonly streetAddress: string;
  readonly city: string;
  readonly state: string;
  readonly postalCode: string;
  readonly phone: string;
  readonly status: string;
}

/** tenant-service GET /v1/internal/tenants/:tenantId/marketplace-profile */
export interface TenantMarketplaceProfile {
  readonly tenantId: string;
  readonly businessName: string;
  readonly businessType: ShopCategory;
  readonly ownerName: string;
  readonly ownerPhone: string;
  readonly status: string;
  readonly services: readonly ShopCategory[];
  readonly branches: readonly TenantBranch[];
}

/** The live business identity used when listing search results. */
export interface TenantSummary {
  readonly tenantId: string;
  readonly businessName: string;
  readonly ownerPhone: string;
  readonly status: string;
}

/** Reads trusted shop data from tenant-service's internal API (shared-secret protected). */
@Injectable()
export class TenantDirectoryClient {
  private readonly logger = new Logger(TenantDirectoryClient.name);

  constructor(private readonly configService: ConfigService) {}

  async getMarketplaceProfile(tenantId: string): Promise<TenantMarketplaceProfile> {
    const response = await this.request(
      `/internal/tenants/${encodeURIComponent(tenantId)}/marketplace-profile`,
    );
    return (await response.json()) as TenantMarketplaceProfile;
  }

  /**
   * Live name/phone/status for the shops on a search page. Returns null when
   * tenant-service is unreachable, so callers can fall back to their snapshot
   * instead of failing the whole search.
   */
  async findSummaries(
    tenantIds: readonly string[],
  ): Promise<ReadonlyMap<string, TenantSummary> | null> {
    if (tenantIds.length === 0) return new Map();
    try {
      const params = new URLSearchParams({ tenantIds: [...new Set(tenantIds)].join(',') });
      const response = await this.request(`/internal/tenants?${params.toString()}`);
      const body = (await response.json()) as { readonly items?: readonly TenantSummary[] };
      return new Map((body.items ?? []).map((tenant) => [tenant.tenantId, tenant]));
    } catch (error) {
      this.logger.warn(`Live tenant lookup failed, using listing snapshots: ${String(error)}`);
      return null;
    }
  }

  private async request(path: string): Promise<Response> {
    const baseUrl = this.configService.get<string>(
      'TENANT_SERVICE_BASE_URL',
      'http://localhost:3006/api',
    );
    const sharedSecret = this.configService.get<string>('PLATFORM_ADMIN_INTERNAL_KEY');

    let response: Response;
    try {
      response = await fetch(`${baseUrl.replace(/\/$/, '')}/v1${path}`, {
        headers: sharedSecret ? { 'x-platform-admin-key': sharedSecret } : {},
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
    } catch {
      throw new ServiceUnavailableException('Shop directory is unavailable');
    }
    if (!response.ok) {
      throw new ServiceUnavailableException(`Shop directory returned HTTP ${response.status}`);
    }
    return response;
  }
}
