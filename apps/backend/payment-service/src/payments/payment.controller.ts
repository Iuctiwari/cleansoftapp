import { Body, Controller, Get, Headers, Post, Query, Req } from '@nestjs/common';
import { ApiBearerAuth, ApiOkResponse, ApiOperation, ApiProperty, ApiTags } from '@nestjs/swagger';
import type { PaginatedResult } from '@nexoraa/types';

import { PaymentService } from './payment.service';
import type {
  CreateAdvancePaymentInput,
  PaymentRecord,
  PaymentRequest,
  PaymentStatistics,
} from './payment.types';

class PaymentStatisticsDto implements PaymentStatistics {
  @ApiProperty({ minimum: 0 }) todayCollectedMinor!: number;
  @ApiProperty({ minimum: 0 }) yesterdayCollectedMinor!: number;
  @ApiProperty({ minimum: 0 }) todayCollectedCount!: number;
  @ApiProperty({ minimum: 0 }) totalBills!: number;
  @ApiProperty({ minimum: 0 }) successfulBills!: number;
}

@ApiTags('Payments')
@ApiBearerAuth('access-token')
@Controller({ path: 'payments', version: '1' })
export class PaymentController {
  constructor(private readonly service: PaymentService) {}

  @Get('statistics')
  @ApiOperation({
    summary: 'Get database-aggregated payment statistics for the authenticated branch',
  })
  @ApiOkResponse({ type: PaymentStatisticsDto })
  statistics(
    @Req() request: PaymentRequest,
    @Query('customerId') customerId?: string,
  ): Promise<PaymentStatistics> {
    if (!request.paymentScope) throw new Error('Payment authentication middleware was not applied');
    return this.service.statistics(request.paymentScope, customerId);
  }

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
