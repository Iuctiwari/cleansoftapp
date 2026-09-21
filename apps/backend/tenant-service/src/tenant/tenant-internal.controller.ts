import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';
import { TenantService } from './tenant.service';
import type { TenantListPage, TenantListQuery, TenantRecord, TenantStatus } from './tenant.types';

/**
 * Service-to-service only — excluded from Swagger. Replaces
 * platform-admin-service's direct cross-service Mongo read
 * (TenantServiceConnectionFactory) with a proper HTTP contract, so a schema
 * change here can't silently break the Company Admin panel — see the
 * tenant-data-layer investigation this was built from. Called by
 * platform-admin-service's tenant-directory and tenant-status lookups,
 * never by a browser/app client directly.
 */
@ApiExcludeController()
@Controller({ path: 'internal/tenants', version: '1' })
@UseGuards(PlatformAdminInternalGuard)
export class TenantInternalController {
  constructor(private readonly tenantService: TenantService) {}

  @Get()
  list(
    @Query('search') search?: string,
    @Query('status') status?: TenantStatus,
    @Query('tenantIds') tenantIds?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ): Promise<TenantListPage> {
    const query: TenantListQuery = {
      search,
      status,
      tenantIds: tenantIds
        ? tenantIds
            .split(',')
            .map((id) => id.trim())
            .filter((id) => id.length > 0)
        : undefined,
      page: page ? Number(page) : undefined,
      limit: limit ? Number(limit) : undefined,
    };
    return this.tenantService.listAllForAdmin(query);
  }

  @Get(':tenantId')
  getById(@Param('tenantId') tenantId: string): Promise<TenantRecord> {
    return this.tenantService.getTenantById(tenantId);
  }
}
