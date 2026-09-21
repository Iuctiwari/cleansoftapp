import { Body, Controller, Get, Param, ParseEnumPipe, Put, Req, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformRoleGuard, type PlatformAdminRequest } from '../admin-auth/platform-role.guard';
import { SetModuleAccessDto } from './dtos/set-module-access.dto';
import { ModuleKey } from './module-key.enum';
import { TenantModuleAccessService, type ModuleMatrixEntry } from './tenant-module-access.service';

function actorId(request: PlatformAdminRequest): string {
  if (!request.platformAdmin) throw new Error('PlatformRoleGuard was not applied');
  return request.platformAdmin.id;
}

/**
 * The controller Phase 2 explicitly didn't build (schema + guard only, by
 * design at the time). Added now because module_matrix_screen.dart needs an
 * HTTP surface to read/edit TenantModuleAccess — no new business logic here,
 * just exposing the repository methods Phase 2 already wrote.
 */
@ApiTags('Platform Admin Module Access')
@Controller('platform-admin/tenants/:tenantId/modules')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(PlatformRoleGuard)
export class TenantModuleAccessController {
  constructor(private readonly tenantModuleAccessService: TenantModuleAccessService) {}

  @Get()
  @ApiOperation({
    summary: 'Get the full module matrix for a tenant (every ModuleKey, enabled or not)',
  })
  getMatrix(@Param('tenantId') tenantId: string): Promise<readonly ModuleMatrixEntry[]> {
    return this.tenantModuleAccessService.getMatrix(tenantId);
  }

  @Put(':moduleKey')
  @ApiOperation({ summary: 'Enable/disable a single module for a tenant' })
  setModule(
    @Req() request: PlatformAdminRequest,
    @Param('tenantId') tenantId: string,
    @Param('moduleKey', new ParseEnumPipe(ModuleKey)) moduleKey: ModuleKey,
    @Body() body: SetModuleAccessDto,
  ): Promise<ModuleMatrixEntry> {
    return this.tenantModuleAccessService.setModule(tenantId, moduleKey, body, actorId(request));
  }
}
