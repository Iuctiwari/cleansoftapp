import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';
import type { TenantEnforcementResponse } from '@nexoraa/tenant-enforcement-client';

import { EnforcementService } from './enforcement.service';
import { InternalServiceGuard } from './internal-service.guard';

/**
 * Service-to-service only — excluded from Swagger (this is not part of the
 * admin-facing or tenant-facing API surface). Called by every other
 * service's TenantEnforcementGuard (@nexoraa/tenant-enforcement-client),
 * never by a browser/app client directly.
 */
@ApiExcludeController()
@Controller('platform-admin/internal/enforcement')
@UseGuards(InternalServiceGuard)
export class EnforcementController {
  constructor(private readonly enforcementService: EnforcementService) {}

  @Get(':tenantId')
  getStatus(@Param('tenantId') tenantId: string): Promise<TenantEnforcementResponse> {
    return this.enforcementService.getEnforcementStatus(tenantId);
  }
}
