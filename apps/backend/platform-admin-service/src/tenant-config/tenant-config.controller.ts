import { Controller, Get, Req } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

import type { TenantConfigRequest } from './tenant-config.guard-types';
import { TenantConfigService, type ActiveTenantConfig } from './tenant-config.service';

@ApiTags('Tenant Config')
@Controller('tenant/config')
export class TenantConfigController {
  constructor(private readonly tenantConfigService: TenantConfigService) {}

  /**
   * NOT guarded by PlatformRoleGuard — see TenantAuthMiddleware, applied in
   * TenantConfigModule.configure(). Auth here is the tenant/staff token
   * issued by auth-service, the same as every other tenant-facing route in
   * this repo (settings-services, order-service).
   */
  @Get('active')
  @ApiOperation({ summary: "Boot-time config: the tenant's active theme + enabled modules" })
  getActiveConfig(@Req() request: TenantConfigRequest): Promise<ActiveTenantConfig> {
    if (!request.trustedContext) throw new Error('TenantAuthMiddleware was not applied');
    return this.tenantConfigService.getActiveConfig(request.trustedContext.tenantId);
  }
}
