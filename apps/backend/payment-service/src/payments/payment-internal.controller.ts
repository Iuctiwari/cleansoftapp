import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { PaymentService } from './payment.service';
import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';
import type { TenantPaymentSummary } from './payment.types';

/**
 * Service-to-service only — excluded from Swagger. Called by
 * platform-admin-service's Company Admin panel (tenant detail screen), never
 * by a browser/app client directly.
 */
@ApiExcludeController()
@Controller({ path: 'internal/tenants/:tenantId/payment-summary', version: '1' })
@UseGuards(PlatformAdminInternalGuard)
export class PaymentInternalController {
  constructor(private readonly paymentService: PaymentService) {}

  @Get()
  getSummary(@Param('tenantId') tenantId: string): Promise<TenantPaymentSummary> {
    return this.paymentService.getSummaryForTenant(tenantId);
  }
}
