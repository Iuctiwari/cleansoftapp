import {
  BadGatewayException,
  BadRequestException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { CatalogDependencies, CatalogScope } from './catalog.types';

function record(value: unknown): Record<string, unknown> | undefined {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

@Injectable()
export class HttpCatalogDependencies implements CatalogDependencies {
  constructor(private readonly configService: ConfigService) {}

  async assertBranches(scope: CatalogScope, branchIds: readonly string[]): Promise<void> {
    const unique = [...new Set(branchIds.map((id) => id.trim()).filter(Boolean))];
    if (unique.length === 0) return;
    const baseUrl = this.configService
      .get<string>('BRANCH_SERVICE_BASE_URL', 'http://localhost:3004')
      .replace(/\/$/, '');
    let response: Response;
    try {
      response = await fetch(`${baseUrl}/v1/branches?page=1&pageSize=100`, {
        headers: { authorization: scope.authorization, 'x-branch-id': scope.branchId },
      });
    } catch {
      throw new BadGatewayException('Branch Service is unavailable');
    }
    if (response.status === 403) throw new ForbiddenException('Branch access is forbidden');
    if (!response.ok) throw new BadGatewayException('Branch Service request failed');
    let body: unknown;
    try {
      body = await response.json();
    } catch {
      throw new BadGatewayException('Branch Service returned an invalid response');
    }
    const envelope = record(body);
    const data = envelope && 'data' in envelope ? envelope.data : body;
    const page = record(data);
    const items = Array.isArray(data) ? data : Array.isArray(page?.items) ? page.items : [];
    const valid = new Set(
      items
        .map(record)
        .filter((item): item is Record<string, unknown> => !!item)
        .filter(
          (item) =>
            String(item.tenantId) === scope.tenantId &&
            String(item.status).toLowerCase() === 'active',
        )
        .map((item) => String(item.branchId ?? item.id)),
    );
    if (unique.some((id) => !valid.has(id)))
      throw new BadRequestException(
        'One or more branches are invalid, inactive, or outside the tenant',
      );
  }
}
