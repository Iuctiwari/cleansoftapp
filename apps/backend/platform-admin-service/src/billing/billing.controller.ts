import {
  BadRequestException,
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Req,
  UseGuards,
  type RawBodyRequest,
} from '@nestjs/common';
import { ApiBearerAuth, ApiExcludeEndpoint, ApiOperation, ApiTags } from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import type { BillingAttemptRecord } from './billing.types';
import { BillingService, type CreateOrderResult } from './billing.service';
import { BillingWebhookService } from './billing-webhook.service';
import { CreateBillingOrderDto } from './dtos/create-billing-order.dto';

interface WebhookRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
}

@ApiTags('Platform Admin Billing')
@Controller('platform-admin/billing')
export class BillingController {
  constructor(
    private readonly billingService: BillingService,
    private readonly webhookService: BillingWebhookService,
  ) {}

  @Post('tenants/:tenantId/create-order')
  @ApiBearerAuth(JWT_AUTH_NAME)
  @UseGuards(PlatformRoleGuard)
  @ApiOperation({ summary: 'Create a Razorpay order to bill a tenant for one billing cycle' })
  createOrder(
    @Param('tenantId') tenantId: string,
    @Body() body: CreateBillingOrderDto,
  ): Promise<CreateOrderResult> {
    return this.billingService.createOrderForTenant(tenantId, body.billingCycle);
  }

  @Get('tenants/:tenantId/history')
  @ApiBearerAuth(JWT_AUTH_NAME)
  @UseGuards(PlatformRoleGuard)
  @ApiOperation({ summary: "List a tenant's billing/payment attempt history, newest first" })
  listHistory(@Param('tenantId') tenantId: string): Promise<readonly BillingAttemptRecord[]> {
    return this.billingService.listHistory(tenantId);
  }

  /**
   * Publicly reachable — Razorpay itself calls this, so it deliberately has
   * NO PlatformRoleGuard. Trust comes entirely from the webhook signature
   * verified inside BillingWebhookService; nothing here (or there) acts on
   * the payload before that check passes.
   */
  @Post('webhooks/razorpay')
  @HttpCode(HttpStatus.OK)
  @ApiExcludeEndpoint()
  async handleRazorpayWebhook(
    @Req() request: RawBodyRequest<WebhookRequest>,
  ): Promise<{ received: boolean }> {
    if (!request.rawBody) {
      // Without the exact raw bytes Razorpay signed, signature verification
      // is impossible — fail closed rather than falling back to a
      // re-serialized body that may not byte-match what was actually signed.
      throw new BadRequestException('Raw request body was not captured');
    }

    await this.webhookService.processWebhook(
      request.rawBody,
      this.header(request, 'x-razorpay-signature'),
      this.header(request, 'x-razorpay-event-id'),
    );

    return { received: true };
  }

  private header(request: WebhookRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }
}
