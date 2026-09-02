import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  DEFAULT_PAGE_NUMBER,
  DEFAULT_PAGE_SIZE,
  MAX_PAGE_SIZE,
  SortDirection,
} from '@nexoraa/constants';
import { Transform } from 'class-transformer';
import {
  IsEnum,
  IsIn,
  IsInt,
  IsMongoId,
  IsOptional,
  IsString,
  Max,
  MaxLength,
  Min,
} from 'class-validator';

import { OrderPaymentStatus, OrderStatus } from '../enums';

const STATUS_ALIASES: Readonly<Record<string, OrderStatus>> = Object.freeze({
  ASSIGNED: OrderStatus.ASSIGNED,
  CANCELLED: OrderStatus.CANCELLED,
  CANCELED: OrderStatus.CANCELLED,
  COMPLETED: OrderStatus.DELIVERED,
  DELIVERED: OrderStatus.DELIVERED,
  DRAFT: OrderStatus.DRAFT,
  INPROGRESS: OrderStatus.IN_PROGRESS,
  IN_PROGRESS: OrderStatus.IN_PROGRESS,
  OUTFORDELIVERY: OrderStatus.OUT_FOR_DELIVERY,
  OUT_FOR_DELIVERY: OrderStatus.OUT_FOR_DELIVERY,
  PENDING: OrderStatus.RECEIVED,
  PROCESSING: OrderStatus.IN_PROGRESS,
  READY: OrderStatus.READY,
  RECEIVED: OrderStatus.RECEIVED,
});

function orderStatus(value: unknown): unknown {
  if (typeof value !== 'string') return value;
  return STATUS_ALIASES[value.trim().replace(/[ -]/g, '_').toUpperCase()] ?? value;
}

export class OrderQueryDto {
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
    maxLength: 120,
    description: 'Case-insensitive order-number, customer-name, or customer-mobile search.',
  })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  search?: string;

  @ApiPropertyOptional({
    enum: OrderStatus,
    description:
      'Backend status. Frontend aliases Pending, Processing, and Completed map to Received, InProgress, and Delivered.',
  })
  @Transform(({ value }: { value: unknown }) => orderStatus(value))
  @IsOptional()
  @IsEnum(OrderStatus)
  status?: OrderStatus;

  @ApiPropertyOptional({ enum: OrderPaymentStatus })
  @IsOptional()
  @IsEnum(OrderPaymentStatus)
  paymentStatus?: OrderPaymentStatus;

  @ApiPropertyOptional({ description: 'Must match the authenticated branch when supplied.' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  branchId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsMongoId()
  customerId?: string;

  @ApiPropertyOptional({
    enum: ['createdAt', 'updatedAt', 'orderNumber', 'grandTotal', 'expectedDeliveryDate'],
  })
  @IsOptional()
  @IsIn(['createdAt', 'updatedAt', 'orderNumber', 'grandTotal', 'expectedDeliveryDate'])
  sortBy: 'createdAt' | 'updatedAt' | 'orderNumber' | 'grandTotal' | 'expectedDeliveryDate' =
    'createdAt';

  @ApiPropertyOptional({ enum: SortDirection, default: SortDirection.Descending })
  @IsOptional()
  @IsEnum(SortDirection)
  sortDirection: SortDirection = SortDirection.Descending;
}
