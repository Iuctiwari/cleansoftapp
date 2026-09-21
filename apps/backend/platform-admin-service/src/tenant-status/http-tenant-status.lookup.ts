import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { TenantStatusLookup } from './tenant-status.types';

const REQUEST_TIMEOUT_MS = 3_000;

interface TenantDetailResponse {
  readonly status?: string;
}

/**
 * Calls tenant-service's internal HTTP endpoint (TenantInternalController)
 * instead of connecting to its database directly — replaces
 * MongoTenantStatusLookup/TenantServiceConnectionFactory. Same fail-open
 * contract as before (see TenantStatusLookup's own doc comment): ANY failure
 * — network error, timeout, 404, non-2xx — returns null, never throws.
 * TenantStatusGuard treats null as "unknown, fail open."
 */
@Injectable()
export class HttpTenantStatusLookup implements TenantStatusLookup {
  private readonly logger = new Logger(HttpTenantStatusLookup.name);

  constructor(private readonly configService: ConfigService) {}

  async getTenantStatus(tenantId: string): Promise<string | null> {
    const baseUrl = this.configService.get<string>(
      'TENANT_SERVICE_BASE_URL',
      'http://localhost:3006/api',
    );
    const sharedSecret = this.configService.get<string>('PLATFORM_ADMIN_INTERNAL_KEY');

    let response: Response;
    try {
      response = await fetch(`${baseUrl.replace(/\/$/, '')}/v1/internal/tenants/${tenantId}`, {
        headers: sharedSecret ? { 'x-platform-admin-key': sharedSecret } : {},
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      });
    } catch (error) {
      this.logger.warn(
        `[tenant-status-lookup-failed] reason=connection_error tenantId=${tenantId} failing_open=true: ${(error as Error).message}`,
      );
      return null;
    }

    if (response.status === 404) {
      this.logger.warn(
        `[tenant-status-lookup-failed] reason=not_found tenantId=${tenantId} failing_open=true`,
      );
      return null;
    }

    if (!response.ok) {
      this.logger.warn(
        `[tenant-status-lookup-failed] reason=http_${response.status} tenantId=${tenantId} failing_open=true`,
      );
      return null;
    }

    const body = (await response.json()) as TenantDetailResponse;
    return body.status ?? null;
  }
}
