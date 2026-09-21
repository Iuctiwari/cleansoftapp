import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { CustomerService } from './customer.service';
import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';

/**
 * Service-to-service only — excluded from Swagger. Called by
 * platform-admin-service's Company Admin panel (tenant detail screen), never
 * by a browser/app client directly. No API version prefix — this service
 * doesn't use versioning (see main.ts), unlike order/payment/tenant-service.
 */
@ApiExcludeController()
@Controller('internal/tenants/:tenantId/customer-count')
@UseGuards(PlatformAdminInternalGuard)
export class CustomerInternalController {
  constructor(private readonly customerService: CustomerService) {}

  @Get()
  async getCount(@Param('tenantId') tenantId: string): Promise<{ count: number }> {
    return { count: await this.customerService.countForTenant(tenantId) };
  }
}
