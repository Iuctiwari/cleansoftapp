import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { OrderService } from './order.service';
import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';
import type { TenantOrderSummary } from './order.types';

/**
 * Service-to-service only — excluded from Swagger. Called by
 * platform-admin-service's Company Admin panel (tenant detail screen), never
 * by a browser/app client directly.
 */
@ApiExcludeController()
@Controller({ path: 'internal/tenants/:tenantId/order-summary', version: '1' })
@UseGuards(PlatformAdminInternalGuard)
export class OrderInternalController {
  constructor(private readonly orderService: OrderService) {}

  @Get()
  getSummary(@Param('tenantId') tenantId: string): Promise<TenantOrderSummary> {
    return this.orderService.getOrderSummaryForTenant(tenantId);
  }
}
