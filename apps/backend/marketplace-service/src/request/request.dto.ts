import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsIn,
  IsInt,
  IsISO8601,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  MinLength,
  ValidateNested,
} from 'class-validator';

import { REQUEST_STATUSES, type RequestStatus } from '../platform/marketplace.database';
import {
  SERVICE_MODES,
  SHOP_CATEGORIES,
  type ServiceMode,
  type ShopCategory,
} from '../platform/marketplace.types';

const CLOCK = /^([01]\d|2[0-3]):[0-5]\d$/;

export class TimeSlotDto {
  @ApiProperty({ example: '10:00' })
  @Matches(CLOCK, { message: 'start must be HH:mm' })
  start!: string;

  @ApiProperty({ example: '12:00' })
  @Matches(CLOCK, { message: 'end must be HH:mm' })
  end!: string;
}

export class RequestItemDto {
  @ApiProperty({ example: 'Shirts' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  name!: string;

  @ApiProperty({ example: 5, minimum: 1, maximum: 999 })
  @IsInt()
  @Min(1)
  @Max(999)
  quantity!: number;
}

export class CreateServiceRequestDto {
  @ApiProperty({ description: 'The shop (branch) id from the shop list' })
  @IsString()
  @IsNotEmpty()
  shopId!: string;

  @ApiProperty({ enum: SHOP_CATEGORIES, example: 'laundry' })
  @IsIn(SHOP_CATEGORIES)
  category!: ShopCategory;

  @ApiProperty({ enum: SERVICE_MODES, example: 'pickup_drop' })
  @IsIn(SERVICE_MODES)
  requestType!: ServiceMode;

  @ApiProperty({ example: 'Wash and iron, 2 bedsheets have stains', minLength: 5 })
  @IsString()
  @MinLength(5)
  @MaxLength(1000)
  description!: string;

  @ApiPropertyOptional({ type: [RequestItemDto] })
  @IsOptional()
  @ArrayMaxSize(20)
  @ValidateNested({ each: true })
  @Type(() => RequestItemDto)
  items?: RequestItemDto[];

  @ApiProperty({ description: 'Preferred date (India), YYYY-MM-DD', example: '2026-10-08' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'preferredDate must be YYYY-MM-DD' })
  preferredDate!: string;

  @ApiProperty({ type: TimeSlotDto })
  @ValidateNested()
  @Type(() => TimeSlotDto)
  preferredSlot!: TimeSlotDto;

  @ApiPropertyOptional({
    description: 'Saved address — required for home service and pickup & drop',
  })
  @IsOptional()
  @IsString()
  addressId?: string;
}

export class CancelRequestDto {
  @ApiPropertyOptional({ maxLength: 300 })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  reason?: string;
}

export class AcceptRequestDto {
  @ApiPropertyOptional({
    description:
      'Confirmed date and time (ISO 8601). Defaults to the preferred date and slot start.',
    example: '2026-10-08T10:30:00+05:30',
  })
  @IsOptional()
  @IsISO8601()
  confirmedAt?: string;

  @ApiPropertyOptional({ description: 'Message to the customer', maxLength: 300 })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;

  @ApiPropertyOptional({ description: 'The worker who will go and collect (required for pickup and home service)' })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  workerId?: string;

  @ApiPropertyOptional({ maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  workerName?: string;
}

export class AssignWorkerDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  workerId!: string;

  @ApiProperty({ maxLength: 120 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  workerName!: string;
}

export class CollectRequestDto {
  @ApiProperty({ type: [RequestItemDto], description: 'What was actually collected' })
  @ArrayMinSize(1)
  @ArrayMaxSize(50)
  @ValidateNested({ each: true })
  @Type(() => RequestItemDto)
  items!: RequestItemDto[];

  @ApiPropertyOptional({ description: 'Custom delivery date YYYY-MM-DD; omit to use the automatic date' })
  @IsOptional()
  @Matches(/^d{4}-d{2}-d{2}$/, { message: 'deliveryDate must be YYYY-MM-DD' })
  deliveryDate?: string;

  @ApiPropertyOptional({ maxLength: 300 })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}

export class EstimateQueryDto {
  @ApiProperty({ minimum: 1, maximum: 9999 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(9999)
  quantity!: number;
}

export class DeclineRequestDto {
  @ApiProperty({ description: 'Shown to the customer', minLength: 3, maxLength: 300 })
  @IsString()
  @MinLength(3)
  @MaxLength(300)
  reason!: string;
}

export class LinkOrderDto {
  @ApiProperty({ description: 'The order created for this request' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(64)
  orderId!: string;
}

export class CompleteRequestDto {
  @ApiPropertyOptional({ maxLength: 300 })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  note?: string;
}

export class ListRequestsQueryDto {
  @ApiPropertyOptional({ enum: REQUEST_STATUSES })
  @IsOptional()
  @IsIn(REQUEST_STATUSES)
  status?: RequestStatus;

  @ApiPropertyOptional({ minimum: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ minimum: 1, maximum: 50, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}
