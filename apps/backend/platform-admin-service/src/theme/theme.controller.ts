import { Body, Controller, Get, Param, Put, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformRoleGuard, type PlatformAdminRequest } from '../admin-auth/platform-role.guard';
import { UpdateTenantThemeDto } from './dtos/update-tenant-theme.dto';
import { ThemeService } from './theme.service';
import type { EffectiveTenantTheme } from './theme.types';

function actorId(request: PlatformAdminRequest): string {
  if (!request.platformAdmin) throw new Error('PlatformRoleGuard was not applied');
  return request.platformAdmin.id;
}

@ApiTags('Platform Admin Theming')
@Controller('platform-admin/tenants/:tenantId/theme')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(PlatformRoleGuard)
export class ThemeController {
  constructor(private readonly themeService: ThemeService) {}

  @Get()
  @ApiOperation({
    summary: "Get a tenant's effective theme (their own values, or the app's current defaults)",
  })
  getTheme(@Param('tenantId') tenantId: string): Promise<EffectiveTenantTheme> {
    return this.themeService.getEffectiveTheme(tenantId);
  }

  @Put()
  @ApiOperation({ summary: "Set a tenant's theme (writes a ThemeHistory audit record)" })
  async setTheme(
    @Req() request: PlatformAdminRequest,
    @Param('tenantId') tenantId: string,
    @Body() body: UpdateTenantThemeDto,
  ): Promise<EffectiveTenantTheme> {
    await this.themeService.setTheme(tenantId, body, actorId(request));
    return this.themeService.getEffectiveTheme(tenantId);
  }
}
