import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';
import { UserService } from './user.service';

/**
 * Service-to-service only — excluded from Swagger. Called by
 * platform-admin-service's Company Admin panel (Clients tab), never by a
 * browser/app client directly.
 */
@ApiExcludeController()
@Controller({ path: 'internal/tenants/:tenantId/staff-count', version: '1' })
@UseGuards(PlatformAdminInternalGuard)
export class UserInternalController {
  constructor(private readonly userService: UserService) {}

  @Get()
  async getCount(@Param('tenantId') tenantId: string): Promise<{ count: number }> {
    return { count: await this.userService.countActiveStaffByTenant(tenantId) };
  }
}
