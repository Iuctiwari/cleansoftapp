import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type {
  TenantDirectoryEntry,
  TenantDirectoryPage,
  TenantDirectoryQuery,
  TenantDirectoryRepository,
} from './tenant-directory.types';

const REQUEST_TIMEOUT_MS = 5_000;

interface TenantListResponse {
  readonly items: readonly TenantDirectoryEntry[];
  readonly page: number;
  readonly limit: number;
  readonly total: number;
}

/**
 * Calls tenant-service's internal HTTP endpoint (TenantInternalController)
 * instead of connecting to its database directly — replaces the old
 * TenantServiceConnectionFactory/MongoTenantDirectoryRepository. See the
 * tenant-data-layer investigation this was built from: a direct cross-service
 * Mongo read couples this service to tenant-service's schema with no
 * compile-time or runtime warning on drift; an HTTP contract makes that
 * coupling explicit and versioned.
 */
@Injectable()
export class HttpTenantDirectoryRepository implements TenantDirectoryRepository {
  constructor(private readonly configService: ConfigService) {}

  async list(query: TenantDirectoryQuery): Promise<TenantDirectoryPage> {
    const params = new URLSearchParams();
    if (query.search) params.set('search', query.search);
    if (query.status) params.set('status', query.status);
    if (query.page) params.set('page', String(query.page));
    if (query.limit) params.set('limit', String(query.limit));

    const response = await this.request(`/internal/tenants?${params.toString()}`);
    return (await response.json()) as TenantListResponse;
  }

  async listByTenantIds(tenantIds: readonly string[]): Promise<readonly TenantDirectoryEntry[]> {
    if (tenantIds.length === 0) return [];
    const params = new URLSearchParams({ tenantIds: tenantIds.join(',') });
    const response = await this.request(`/internal/tenants?${params.toString()}`);
    const body = (await response.json()) as TenantListResponse;
    return body.items;
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
    } catch (error) {
      // Propagates — see TenantDirectoryRepository's contract: this method
      // must never silently look like "0 tenants" on a connectivity blip.
      throw new Error(`tenant-service is unreachable: ${(error as Error).message}`, {
        cause: error,
      });
    }

    if (!response.ok) {
      throw new Error(`tenant-service returned HTTP ${response.status}`);
    }

    return response;
  }
}
