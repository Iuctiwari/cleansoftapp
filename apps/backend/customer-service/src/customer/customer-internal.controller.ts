import { Body, Controller, Get, HttpCode, Param, Post, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { LinkOnlineCustomerDto } from './customer.dto';
import { CustomerService } from './customer.service';
import type { OnlineCustomerLink } from './customer.types';
import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';

/**
 * Service-to-service only — excluded from Swagger. Called by
 * platform-admin-service's Company Admin panel (tenant detail screen) and by
 * marketplace-service, never by a browser/app client directly. No API version
 * prefix — this service doesn't use versioning (see main.ts), unlike
 * order/payment/tenant-service.
 */
@ApiExcludeController()
@Controller('internal/tenants/:tenantId')
@UseGuards(PlatformAdminInternalGuard)
export class CustomerInternalController {
  constructor(private readonly customerService: CustomerService) {}

  @Get('customer-count')
  async getCount(@Param('tenantId') tenantId: string): Promise<{ count: number }> {
    return { count: await this.customerService.countForTenant(tenantId) };
  }

  /** A marketplace customer sent this branch a request: put them on its customer list. */
  @Post('branches/:branchId/online-customers')
  @HttpCode(200)
  linkOnlineCustomer(
    @Param('tenantId') tenantId: string,
    @Param('branchId') branchId: string,
    @Body() body: LinkOnlineCustomerDto,
  ): Promise<OnlineCustomerLink> {
    return this.customerService.linkOnlineCustomer(tenantId, branchId, body);
  }
}
