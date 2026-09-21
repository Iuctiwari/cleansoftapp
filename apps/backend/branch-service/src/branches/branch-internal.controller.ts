import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { BranchService } from './branch.service';
import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';

/**
 * Service-to-service only — excluded from Swagger. Called by
 * platform-admin-service's Company Admin panel (Clients tab), never by a
 * browser/app client directly.
 */
@ApiExcludeController()
@Controller({ path: 'internal/tenants/:tenantId/branch-count', version: '1' })
@UseGuards(PlatformAdminInternalGuard)
export class BranchInternalController {
  constructor(private readonly branchService: BranchService) {}

  @Get()
  async getCount(@Param('tenantId') tenantId: string): Promise<{ count: number }> {
    return { count: await this.branchService.getActiveBranchCount(tenantId) };
  }
}
