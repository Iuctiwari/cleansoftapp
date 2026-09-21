import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { TenantResourceCountsService } from './tenant-resource-counts.service';
import type { TenantResourceCounts } from './tenant-resource-counts.types';

@ApiTags('Platform Admin Tenant Resource Counts')
@Controller('platform-admin/tenants/:tenantId/resource-counts')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(PlatformRoleGuard)
export class TenantResourceCountsController {
  constructor(private readonly tenantResourceCountsService: TenantResourceCountsService) {}

  @Get()
  @ApiOperation({
    summary:
      "A tenant's branch/staff counts (cross-service lookup; a null field means that " +
      'lookup failed, not that the count is zero)',
  })
  getCounts(@Param('tenantId') tenantId: string): Promise<TenantResourceCounts> {
    return this.tenantResourceCountsService.getCounts(tenantId);
  }
}
