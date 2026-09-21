import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { ListTenantsDto } from './dtos/list-tenants.dto';
import { OverviewTenantsDto } from './dtos/overview-tenants.dto';
import { TenantDirectoryService } from './tenant-directory.service';
import type { TenantDirectoryPage, TenantOverviewPage } from './tenant-directory.types';

@ApiTags('Platform Admin Tenant Directory')
@Controller('platform-admin/tenants')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(PlatformRoleGuard)
export class TenantDirectoryController {
  constructor(private readonly tenantDirectoryService: TenantDirectoryService) {}

  @Get()
  @ApiOperation({ summary: 'List/search tenants (read-only, sourced from tenant-service)' })
  list(@Query() query: ListTenantsDto): Promise<TenantDirectoryPage> {
    return this.tenantDirectoryService.list(query);
  }

  @Get('overview')
  @ApiOperation({
    summary:
      'Tenant list enriched with subscription plan/status/days-remaining; filterable by ' +
      'planKey or subscriptionStatus (also powers "tenants on this plan")',
  })
  overview(@Query() query: OverviewTenantsDto): Promise<TenantOverviewPage> {
    return this.tenantDirectoryService.overview(query);
  }
}
