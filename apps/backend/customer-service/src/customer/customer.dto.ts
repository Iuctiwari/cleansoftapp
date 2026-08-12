import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsEmail,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DEFAULT_PAGE_NUMBER, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } from '@nexoraa/constants';

import { CustomerType } from './customer.mongoose.schema';

const MOBILE_PATTERN = /^\+?[0-9]{7,15}$/;

export class CreateCustomerDto {
  @ApiProperty({ example: 'Priya Sharma', maxLength: 120 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name!: string;

  @ApiPropertyOptional({
    example: '+919876543210',
    pattern: '^\\+?[0-9]{7,15}$',
    description: 'Required unless customerType is Walk-in.',
  })
  @ValidateIf(
    (value: CreateCustomerDto) =>
      value.customerType !== CustomerType.WALK_IN || value.mobile !== undefined,
  )
  @IsString()
  @IsNotEmpty()
  @Matches(MOBILE_PATTERN)
  mobile?: string;

  @ApiPropertyOptional({ example: 'priya@example.com', maxLength: 160 })
  @IsOptional()
  @IsEmail()
  @MaxLength(160)
  email?: string;

  @ApiPropertyOptional({ example: 'MG Road, Pune', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  address?: string;

  @ApiProperty({ enum: CustomerType, example: CustomerType.REGULAR })
  @IsEnum(CustomerType)
  customerType!: CustomerType;

  @ApiPropertyOptional({
    example: '2026-08-12',
    format: 'date',
    description: 'Defaults to the current date when omitted.',
  })
  @IsOptional()
  @IsDateString({ strict: true })
  joiningDate?: string;
}

export class UpdateCustomerDto {
  @ApiPropertyOptional({ example: 'Priya Sharma', maxLength: 120 })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string;

  @ApiPropertyOptional({
    example: '+919876543210',
    nullable: true,
    pattern: '^\\+?[0-9]{7,15}$',
    type: String,
  })
  @ValidateIf((_value: UpdateCustomerDto, value: unknown) => value !== null && value !== undefined)
  @IsString()
  @Matches(MOBILE_PATTERN)
  mobile?: string | null;

  @ApiPropertyOptional({
    example: 'priya@example.com',
    maxLength: 160,
    nullable: true,
    type: String,
  })
  @ValidateIf((_value: UpdateCustomerDto, value: unknown) => value !== null && value !== undefined)
  @IsEmail()
  @MaxLength(160)
  email?: string | null;

  @ApiPropertyOptional({ example: 'MG Road, Pune', maxLength: 500, nullable: true, type: String })
  @ValidateIf((_value: UpdateCustomerDto, value: unknown) => value !== null && value !== undefined)
  @IsString()
  @MaxLength(500)
  address?: string | null;

  @ApiPropertyOptional({ enum: CustomerType, example: CustomerType.VIP })
  @IsOptional()
  @IsEnum(CustomerType)
  customerType?: CustomerType;

  @ApiPropertyOptional({ example: '2026-08-12', format: 'date' })
  @IsOptional()
  @IsDateString({ strict: true })
  joiningDate?: string;
}

export class ListCustomersQueryDto {
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

  @ApiPropertyOptional({ maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  search?: string;
}

export class CustomerResponseDto {
  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34cd', description: 'Customer identifier.' })
  id!: string;

  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34aa', description: 'Authenticated tenant scope.' })
  tenantId!: string;

  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34bb', description: 'Authenticated branch scope.' })
  branchId!: string;

  @ApiProperty({ example: 'Priya Sharma' })
  name!: string;

  @ApiPropertyOptional({ example: '+919876543210' })
  mobile?: string;

  @ApiPropertyOptional({ example: 'priya@example.com' })
  email?: string;

  @ApiPropertyOptional({ example: 'MG Road, Pune' })
  address?: string;

  @ApiProperty({ enum: CustomerType, example: CustomerType.REGULAR })
  customerType!: CustomerType;

  @ApiProperty({ example: '2026-08-12T00:00:00.000Z', format: 'date-time' })
  joiningDate!: Date;

  @ApiProperty({ example: 0, minimum: 0 })
  totalOrders!: number;

  @ApiProperty({ example: 0, minimum: 0 })
  totalSpent!: number;

  @ApiProperty({ example: 0 })
  outstandingBalance!: number;

  @ApiProperty({ example: null, format: 'date-time', nullable: true, type: String })
  lastOrderDate!: Date | null;

  @ApiProperty({ example: '2026-08-12T10:30:00.000Z', format: 'date-time' })
  createdAt!: Date;

  @ApiProperty({ example: '2026-08-12T10:30:00.000Z', format: 'date-time' })
  updatedAt!: Date;
}

export class CustomerPageResponseDto {
  @ApiProperty({ type: [CustomerResponseDto] })
  items!: CustomerResponseDto[];

  @ApiProperty({ example: 100, minimum: 0 })
  total!: number;

  @ApiProperty({ example: 1, minimum: 1 })
  page!: number;

  @ApiProperty({ example: 20, minimum: 1, maximum: MAX_PAGE_SIZE })
  limit!: number;
}

export class CustomerStatisticsResponseDto {
  @ApiProperty({ example: 100, minimum: 0 })
  total!: number;

  @ApiProperty({ example: 100, minimum: 0 })
  active!: number;

  @ApiProperty({ example: 12500 })
  outstanding!: number;
}

export class CustomerErrorResponseDto {
  @ApiProperty({ example: 400 })
  statusCode!: number;

  @ApiProperty({ example: 'VALIDATION_ERROR' })
  code!: string;

  @ApiProperty({ example: 'Request validation failed' })
  message!: string;

  @ApiProperty({ example: '2026-08-12T10:30:00.000Z', format: 'date-time' })
  timestamp!: string;

  @ApiProperty({ example: '/customers' })
  path!: string;

  @ApiProperty({ example: 'POST' })
  method!: string;

  @ApiPropertyOptional({ example: 'b9a1d970-9868-4a1f-b4f05054cbf2' })
  correlationId?: string;

  @ApiPropertyOptional({ type: Object, description: 'Safe validation or application details.' })
  details?: unknown;
}
