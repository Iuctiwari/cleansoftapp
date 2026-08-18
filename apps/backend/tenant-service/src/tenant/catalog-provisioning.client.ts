import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { TenantError } from './tenant.errors';
import type { CatalogProvisioningCandidate, TenantCatalogProvisioner } from './tenant.types';

@Injectable()
export class HttpTenantCatalogProvisioner implements TenantCatalogProvisioner {
  constructor(private readonly configService: ConfigService) {}

  async provision(candidate: CatalogProvisioningCandidate): Promise<void> {
    if (candidate.businessTypes.length === 0) return;
    const baseUrl = this.configService
      .get<string>('SERVICE_MANAGEMENT_BASE_URL', 'http://localhost:3010/api')
      .replace(/\/$/, '');
    const key = this.configService.get<string>('CATALOG_PROVISIONING_KEY')?.trim();
    if (!key) throw this.failure('Catalog provisioning credentials are not configured');
    let response: Response;
    try {
      response = await fetch(`${baseUrl}/v1/catalog/provision`, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          'x-catalog-provisioning-key': key,
        },
        body: JSON.stringify({
          tenantId: candidate.tenantId,
          actorId: candidate.ownerUserId,
          businessTypes: candidate.businessTypes,
        }),
        signal: AbortSignal.timeout(120_000),
      });
    } catch {
      throw this.failure('Service Management is unavailable during catalog provisioning');
    }
    if (!response.ok) {
      throw this.failure(`Service Management rejected catalog provisioning (${response.status})`);
    }
  }

  private failure(message: string): TenantError {
    return new TenantError({
      code: 'tenant.catalog_provisioning_failed',
      category: 'internal',
      messageKey: 'errors.tenant.catalog_provisioning_failed',
      fields: [{ field: 'services', code: message }],
    });
  }
}
