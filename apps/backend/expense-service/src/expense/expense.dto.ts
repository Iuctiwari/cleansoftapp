import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsPositive,
  IsString,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DEFAULT_PAGE_NUMBER, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } from '@nexoraa/constants';

import { ExpenseCategoryStatus, ExpensePaymentMethod } from './expense.mongoose.schema';

export class CreateExpenseCategoryDto {
  @ApiProperty({ example: 'Utilities', maxLength: 100 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  categoryName!: string;

  @ApiPropertyOptional({ example: 'Electricity, water, gas, internet bills', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ enum: ExpenseCategoryStatus, default: ExpenseCategoryStatus.ACTIVE })
  @IsOptional()
  @IsEnum(ExpenseCategoryStatus)
  status?: ExpenseCategoryStatus;
}

export class ExpenseCategoryResponseDto {
  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34cd' })
  id!: string;

  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34aa' })
  tenantId!: string;

  @ApiProperty({ example: 'Utilities' })
  categoryName!: string;

  @ApiPropertyOptional({ example: 'Electricity and water bills' })
  description?: string;

  @ApiProperty({ enum: ExpenseCategoryStatus, example: ExpenseCategoryStatus.ACTIVE })
  status!: ExpenseCategoryStatus;

  @ApiProperty({ example: '2026-08-12T10:30:00.000Z', format: 'date-time' })
  createdAt!: Date;

  @ApiProperty({ example: '2026-08-12T10:30:00.000Z', format: 'date-time' })
  updatedAt!: Date;
}

export class CreateExpenseDto {
  @ApiProperty({
    example: '64f0c18f7c4d2f0012ab34cd',
    description: 'Expense category MongoDB ObjectId.',
  })
  @IsString()
  @IsNotEmpty()
  expenseCategoryId!: string;

  @ApiProperty({
    example: 4500.5,
    minimum: 0.01,
    description: 'Expense amount, must be greater than 0.',
  })
  @IsNumber()
  @IsPositive()
  amount!: number;

  @ApiProperty({ enum: ExpensePaymentMethod, example: ExpensePaymentMethod.CASH })
  @IsEnum(ExpensePaymentMethod)
  paymentMethod!: ExpensePaymentMethod;

  @ApiPropertyOptional({ example: 'State Electricity Board', maxLength: 150 })
  @IsOptional()
  @IsString()
  @MaxLength(150)
  vendor?: string;

  @ApiProperty({ example: 'Main Branch electricity bill payment', maxLength: 500 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  description!: string;

  @ApiPropertyOptional({
    example: 'https://storage.nexoraa.com/receipts/rec_123.pdf',
    maxLength: 1000,
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  attachment?: string;

  @ApiPropertyOptional({
    example: '2026-08-18T10:00:00.000Z',
    format: 'date-time',
    description: 'Defaults to the current timestamp when omitted.',
  })
  @IsOptional()
  @IsDateString()
  expenseDate?: string;
}

export class UpdateExpenseDto {
  @ApiPropertyOptional({
    example: '64f0c18f7c4d2f0012ab34cd',
    description: 'Expense category MongoDB ObjectId.',
  })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  expenseCategoryId?: string;

  @ApiPropertyOptional({ example: 5000, minimum: 0.01 })
  @IsOptional()
  @IsNumber()
  @IsPositive()
  amount?: number;

  @ApiPropertyOptional({ enum: ExpensePaymentMethod, example: ExpensePaymentMethod.UPI })
  @IsOptional()
  @IsEnum(ExpensePaymentMethod)
  paymentMethod?: ExpensePaymentMethod;

  @ApiPropertyOptional({ example: 'State Electricity Board', maxLength: 150, nullable: true })
  @ValidateIf((_value: UpdateExpenseDto, value: unknown) => value !== null && value !== undefined)
  @IsString()
  @MaxLength(150)
  vendor?: string | null;

  @ApiPropertyOptional({ example: 'Updated electricity bill payment', maxLength: 500 })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({
    example: 'https://storage.nexoraa.com/receipts/rec_123.pdf',
    maxLength: 1000,
    nullable: true,
  })
  @ValidateIf((_value: UpdateExpenseDto, value: unknown) => value !== null && value !== undefined)
  @IsString()
  @MaxLength(1000)
  attachment?: string | null;

  @ApiPropertyOptional({ example: '2026-08-18T10:00:00.000Z', format: 'date-time' })
  @IsOptional()
  @IsDateString()
  expenseDate?: string;
}

export class ListExpensesQueryDto {
  @ApiPropertyOptional({ default: DEFAULT_PAGE_NUMBER, minimum: 1 })
  @Transform(({ value }: { value: unknown }) => Number(value))
  @IsInt()
  @Min(1)
  page: number = DEFAULT_PAGE_NUMBER;

  @ApiPropertyOptional({ default: DEFAULT_PAGE_SIZE, minimum: 1, maximum: MAX_PAGE_SIZE })
  @Transform(({ value }: { value: unknown }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(MAX_PAGE_SIZE)
  limit: number = DEFAULT_PAGE_SIZE;

  @ApiPropertyOptional({
    example: '64f0c18f7c4d2f0012ab34cd',
    description: 'Filter by Category ID.',
  })
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiPropertyOptional({ example: 'branch_01', description: 'Filter by Branch ID.' })
  @IsOptional()
  @IsString()
  branchId?: string;

  @ApiPropertyOptional({ enum: ExpensePaymentMethod, description: 'Filter by Payment Method.' })
  @IsOptional()
  @IsEnum(ExpensePaymentMethod)
  paymentMethod?: ExpensePaymentMethod;

  @ApiPropertyOptional({ example: '2026-08-01', format: 'date', description: 'Start date filter.' })
  @IsOptional()
  @IsDateString()
  startDate?: string;

  @ApiPropertyOptional({ example: '2026-08-31', format: 'date', description: 'End date filter.' })
  @IsOptional()
  @IsDateString()
  endDate?: string;

  @ApiPropertyOptional({ maxLength: 120, description: 'Search vendor or description.' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  search?: string;
}

export class ExpenseResponseDto {
  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34cd' })
  id!: string;

  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34aa' })
  tenantId!: string;

  @ApiProperty({ example: 'branch_01' })
  branchId!: string;

  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34cd' })
  expenseCategoryId!: string;

  @ApiPropertyOptional({ example: 'Utilities' })
  categoryName?: string;

  @ApiProperty({ example: 4500.5 })
  amount!: number;

  @ApiProperty({ enum: ExpensePaymentMethod, example: ExpensePaymentMethod.CASH })
  paymentMethod!: ExpensePaymentMethod;

  @ApiPropertyOptional({ example: 'State Electricity Board' })
  vendor?: string;

  @ApiProperty({ example: 'Electricity bill for July' })
  description!: string;

  @ApiPropertyOptional({ example: 'https://storage.nexoraa.com/receipts/rec_123.pdf' })
  attachment?: string;

  @ApiProperty({ example: '2026-08-18T10:00:00.000Z', format: 'date-time' })
  expenseDate!: Date;

  @ApiProperty({ example: 'user_123' })
  recordedBy!: string;

  @ApiProperty({ example: '2026-08-18T10:30:00.000Z', format: 'date-time' })
  createdAt!: Date;

  @ApiProperty({ example: '2026-08-18T10:30:00.000Z', format: 'date-time' })
  updatedAt!: Date;
}

export class ExpensePageResponseDto {
  @ApiProperty({ type: [ExpenseResponseDto] })
  items!: ExpenseResponseDto[];

  @ApiProperty({ example: 25, minimum: 0 })
  total!: number;

  @ApiProperty({ example: 1, minimum: 1 })
  page!: number;

  @ApiProperty({ example: 20, minimum: 1, maximum: MAX_PAGE_SIZE })
  limit!: number;
}

export class ExpenseStatisticsResponseDto {
  @ApiProperty({ example: 34500 })
  totalAmount!: number;

  @ApiProperty({ example: 12 })
  count!: number;

  @ApiProperty({ example: 5 })
  categoryCount!: number;

  @ApiProperty({ example: { Cash: 12000, UPI: 15000, Card: 7500 } })
  byPaymentMethod!: Record<string, number>;
}

export class ExpenseErrorResponseDto {
  @ApiProperty({ example: 400 })
  statusCode!: number;

  @ApiProperty({ example: 'VALIDATION_ERROR' })
  code!: string;

  @ApiProperty({ example: 'Request validation failed' })
  message!: string;

  @ApiProperty({ example: '2026-08-18T10:30:00.000Z', format: 'date-time' })
  timestamp!: string;

  @ApiProperty({ example: '/expenses' })
  path!: string;

  @ApiProperty({ example: 'POST' })
  method!: string;

  @ApiPropertyOptional({ example: 'b9a1d970-9868-4a1f-b4f05054cbf2' })
  correlationId?: string;

  @ApiPropertyOptional({ type: Object, description: 'Validation details.' })
  details?: unknown;
}
