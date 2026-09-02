import { Transform } from 'class-transformer';
import { IsDateString, IsEnum, IsInt, IsOptional, Max, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DEFAULT_PAGE_NUMBER, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } from '@nexoraa/constants';

export enum ReportPeriod {
  SEVEN_DAYS = '7d',
  THIRTY_DAYS = '30d',
  THREE_MONTHS = '3m',
  YEAR = '1y',
}

export class ReportSummaryQueryDto {
  @ApiPropertyOptional({ default: ReportPeriod.SEVEN_DAYS, enum: ReportPeriod })
  @IsOptional()
  @IsEnum(ReportPeriod)
  period: ReportPeriod = ReportPeriod.SEVEN_DAYS;

  @ApiPropertyOptional({
    description: 'Custom inclusive range start. Must be supplied with endDate.',
    example: '2026-08-01T00:00:00.000Z',
    format: 'date-time',
  })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({
    description: 'Custom inclusive range end. Must be supplied with startDate.',
    example: '2026-08-31T23:59:59.999Z',
    format: 'date-time',
  })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}

export class ReportListQueryDto {
  @ApiPropertyOptional({
    description: 'Preset date range. Explicit startDate/endDate take precedence.',
    enum: ReportPeriod,
  })
  @IsOptional()
  @IsEnum(ReportPeriod)
  period?: ReportPeriod;

  @ApiPropertyOptional({ default: DEFAULT_PAGE_NUMBER, minimum: 1 })
  @Transform(({ value }: { value: unknown }) => Number(value))
  @IsInt()
  @Min(1)
  page: number = DEFAULT_PAGE_NUMBER;

  @ApiPropertyOptional({ default: DEFAULT_PAGE_SIZE, maximum: MAX_PAGE_SIZE, minimum: 1 })
  @Transform(({ value }: { value: unknown }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(MAX_PAGE_SIZE)
  limit: number = DEFAULT_PAGE_SIZE;

  @ApiPropertyOptional({ example: '2026-08-01T00:00:00.000Z', format: 'date-time' })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ example: '2026-08-31T23:59:59.999Z', format: 'date-time' })
  @IsOptional()
  @IsDateString()
  endDate?: string;
}

export class ReportTrendPointDto {
  @ApiProperty({ example: 'Mon' })
  label!: string;

  @ApiProperty({ example: 18, minimum: 0 })
  orders!: number;

  @ApiProperty({ example: 12000, minimum: 0 })
  revenue!: number;
}

export class ReportServiceBreakdownDto {
  @ApiProperty({ example: 'Wash & Fold' })
  name!: string;

  @ApiProperty({ example: 42, maximum: 100, minimum: 0 })
  percentage!: number;
}

export class ReportSummaryResponseDto {
  @ApiProperty({ example: 118000, minimum: 0 })
  collected!: number;

  @ApiProperty({ example: 94.4, minimum: 0 })
  collectionRate!: number;

  @ApiProperty({ example: 43200 })
  netProfit!: number;

  @ApiProperty({ description: 'Order-count change from the immediately preceding period.' })
  orderChange!: number;

  @ApiProperty({ type: [ReportServiceBreakdownDto] })
  serviceBreakdown!: ReportServiceBreakdownDto[];

  @ApiProperty({ example: 174, minimum: 0 })
  totalOrders!: number;

  @ApiProperty({ example: 125000, minimum: 0 })
  totalRevenue!: number;

  @ApiProperty({ description: 'Revenue percentage change from the preceding period.' })
  revenueChange!: number;

  @ApiProperty({ type: [ReportTrendPointDto] })
  trend!: ReportTrendPointDto[];
}

export class BranchPerformanceMetricsDto {
  @ApiProperty({ example: 18, minimum: 0 }) orders!: number;
  @ApiProperty({ example: 13200, minimum: 0 }) revenue!: number;
  @ApiProperty({ example: 12100, minimum: 0 }) collected!: number;
  @ApiProperty({ example: 1100, minimum: 0 }) outstanding!: number;
  @ApiProperty({ example: 3400, minimum: 0 }) expenses!: number;
  @ApiProperty({ example: 9800 }) netProfit!: number;
  @ApiProperty({ example: 72, maximum: 100, minimum: 0 })
  revenueSharePercentage!: number;
}

export class BranchPerformanceRecordDto {
  @ApiProperty() branchId!: string;
  @ApiProperty() branchName!: string;
  @ApiPropertyOptional() branchCode?: string;
  @ApiProperty({ type: BranchPerformanceMetricsDto })
  metrics!: BranchPerformanceMetricsDto;
}

export class BranchPerformanceResponseDto {
  @ApiProperty({ type: [BranchPerformanceRecordDto] })
  branches!: BranchPerformanceRecordDto[];
}

export class ReportAmountTrendPointDto {
  @ApiProperty({ example: '2026-08-25T00:00:00.000Z', format: 'date-time' })
  date!: Date;

  @ApiProperty({ example: 12, minimum: 0 })
  count!: number;

  @ApiProperty({ example: 45000, description: 'Amount in the source collection currency unit.' })
  amount!: number;
}

export class ReportOrderMetricsDto {
  @ApiProperty({ example: 174, minimum: 0 }) totalOrders!: number;
  @ApiProperty({ example: 80, minimum: 0 }) completedOrders!: number;
  @ApiProperty({ example: 82, minimum: 0 }) pendingOrders!: number;
  @ApiProperty({ example: 12, minimum: 0 }) cancelledOrders!: number;
  @ApiProperty({ example: 125000 }) totalOrderValue!: number;
  @ApiProperty({ example: 7000 }) totalOutstandingAmount!: number;
  @ApiProperty({ additionalProperties: { type: 'number' }, type: 'object' })
  statusBreakdown!: Record<string, number>;
  @ApiProperty({ type: [ReportTrendPointDto] }) trend!: ReportTrendPointDto[];
}

export class ReportPaymentMetricsDto {
  @ApiProperty({ example: 24, minimum: 0 }) paymentCount!: number;
  @ApiProperty({ description: 'All payment amounts in minor units.', example: 12500000 })
  totalPaymentAmountMinor!: number;
  @ApiProperty({ description: 'Successful payment amounts in minor units.', example: 11800000 })
  collectedAmountMinor!: number;
  @ApiProperty({ description: 'Pending payment amounts in minor units.', example: 500000 })
  pendingAmountMinor!: number;
  @ApiProperty({ description: 'Failed payment amounts in minor units.', example: 200000 })
  failedAmountMinor!: number;
  @ApiProperty({ additionalProperties: { type: 'number' }, type: 'object' })
  statusBreakdown!: Record<string, number>;
  @ApiProperty({ type: [ReportAmountTrendPointDto] }) trend!: ReportAmountTrendPointDto[];
}

export class ReportExpenseCategoryBreakdownDto {
  @ApiProperty() categoryId!: string;
  @ApiPropertyOptional() categoryName?: string;
  @ApiProperty({ example: 10, minimum: 0 }) count!: number;
  @ApiProperty({ example: 32000 }) amount!: number;
}

export class ReportExpenseMetricsDto {
  @ApiProperty({ example: 12, minimum: 0 }) expenseCount!: number;
  @ApiProperty({ example: 34500 }) totalExpenses!: number;
  @ApiProperty({ type: [ReportExpenseCategoryBreakdownDto] })
  categoryBreakdown!: ReportExpenseCategoryBreakdownDto[];
  @ApiProperty({ type: [ReportAmountTrendPointDto] }) trend!: ReportAmountTrendPointDto[];
}

export class ReportOrderResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() branchId!: string;
  @ApiProperty() orderNumber!: string;
  @ApiProperty() customerId!: string;
  @ApiProperty({ type: Object }) customerSnapshot!: Record<string, unknown>;
  @ApiProperty() status!: string;
  @ApiProperty() paymentStatus!: string;
  @ApiProperty() subtotal!: number;
  @ApiProperty() discount!: number;
  @ApiProperty() tax!: number;
  @ApiProperty() grandTotal!: number;
  @ApiProperty() paidAmount!: number;
  @ApiProperty() outstandingAmount!: number;
  @ApiProperty({ format: 'date-time' }) createdAt!: Date;
  @ApiProperty({ format: 'date-time' }) updatedAt!: Date;
}

export class ReportPaymentResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() branchId!: string;
  @ApiProperty() orderId!: string;
  @ApiProperty() customerId!: string;
  @ApiProperty() paymentNumber!: string;
  @ApiProperty() paymentType!: string;
  @ApiProperty() method!: string;
  @ApiProperty() amountMinor!: number;
  @ApiProperty() currency!: string;
  @ApiProperty() status!: string;
  @ApiProperty() recordedBy!: string;
  @ApiProperty({ format: 'date-time' }) createdAt!: Date;
  @ApiProperty({ format: 'date-time' }) updatedAt!: Date;
}

export class ReportExpenseResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() branchId!: string;
  @ApiProperty() expenseCategoryId!: string;
  @ApiProperty() amount!: number;
  @ApiProperty() paymentMethod!: string;
  @ApiPropertyOptional() vendor?: string;
  @ApiProperty() description!: string;
  @ApiPropertyOptional() attachment?: string;
  @ApiProperty({ format: 'date-time' }) expenseDate!: Date;
  @ApiProperty() recordedBy!: string;
  @ApiProperty({ format: 'date-time' }) createdAt!: Date;
  @ApiProperty({ format: 'date-time' }) updatedAt!: Date;
}

export class ReportOrderPageResponseDto {
  @ApiProperty({ type: [ReportOrderResponseDto] }) items!: ReportOrderResponseDto[];
  @ApiProperty() total!: number;
  @ApiProperty() page!: number;
  @ApiProperty() limit!: number;
  @ApiProperty() totalPages!: number;
  @ApiProperty({ type: ReportOrderMetricsDto }) metrics!: ReportOrderMetricsDto;
}

export class ReportPaymentPageResponseDto {
  @ApiProperty({ type: [ReportPaymentResponseDto] }) items!: ReportPaymentResponseDto[];
  @ApiProperty() total!: number;
  @ApiProperty() page!: number;
  @ApiProperty() limit!: number;
  @ApiProperty() totalPages!: number;
  @ApiProperty({ type: ReportPaymentMetricsDto }) metrics!: ReportPaymentMetricsDto;
}

export class ReportExpensePageResponseDto {
  @ApiProperty({ type: [ReportExpenseResponseDto] }) items!: ReportExpenseResponseDto[];
  @ApiProperty() total!: number;
  @ApiProperty() page!: number;
  @ApiProperty() limit!: number;
  @ApiProperty() totalPages!: number;
  @ApiProperty({ type: ReportExpenseMetricsDto }) metrics!: ReportExpenseMetricsDto;
}
