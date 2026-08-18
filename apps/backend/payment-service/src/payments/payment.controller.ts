import { Body, Controller, Get, Headers, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import type { PaginatedResult } from '@nexoraa/types';

import { PaymentService } from './payment.service';
import type { CreateAdvancePaymentInput, PaymentRecord, PaymentRequest } from './payment.types';

@ApiTags('Payments')
@ApiBearerAuth('access-token')
@Controller({ path: 'payments', version: '1' })
export class PaymentController {
  constructor(private readonly service: PaymentService) {}

  @Post()
  @ApiOperation({ summary: 'Record an idempotent advance payment against an order' })
  create(
    @Req() request: PaymentRequest,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() body: CreateAdvancePaymentInput,
  ): Promise<Record<string, unknown>> {
    if (!request.paymentScope) throw new Error('Payment authentication middleware was not applied');
    return this.service.createAdvance(request.paymentScope, idempotencyKey, body);
  }

  @Get()
  @ApiOperation({
    summary: 'List, filter, sort, and paginate scoped payments, newest first by default',
  })
  list(
    @Req() request: PaymentRequest,
    @Query() query: Record<string, unknown>,
  ): Promise<PaginatedResult<PaymentRecord>> {
    if (!request.paymentScope) throw new Error('Payment authentication middleware was not applied');
    return this.service.list(request.paymentScope, query);
  }
}
