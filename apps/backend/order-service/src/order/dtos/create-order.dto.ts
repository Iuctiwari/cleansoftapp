import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsMongoId,
  IsNumber,
  IsOptional,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

import { OrderItemDto } from './order-item.dto';

export class CreateOrderDto {
  @ApiProperty({
    description: 'Existing customer identifier in the authenticated tenant and branch.',
  })
  @IsMongoId()
  customerId!: string;

  @ApiProperty({ type: [OrderItemDto], minItems: 1 })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items!: OrderItemDto[];

  @ApiPropertyOptional({
    default: 0,
    minimum: 0,
    description: 'Requested absolute order discount; validated and applied by the backend.',
  })
  @IsOptional()
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0)
  discount: number = 0;

  @ApiPropertyOptional({
    default: 0,
    maximum: 100,
    minimum: 0,
    description:
      'Percentage order discount. The backend derives the monetary discount and taxable total.',
  })
  @IsOptional()
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100)
  discountPercentage?: number;

  @ApiPropertyOptional({
    default: 0,
    deprecated: true,
    minimum: 0,
    description: 'Ignored. Tax is derived from authoritative catalog quotes.',
  })
  @IsOptional()
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0)
  tax: number = 0;

  @ApiPropertyOptional({ format: 'date-time' })
  @IsOptional()
  @IsDateString({ strict: true })
  expectedDeliveryDate?: string;

  @ApiPropertyOptional({ description: 'Eligible staff member in the authenticated branch.' })
  @IsOptional()
  @IsMongoId()
  assignedTo?: string;
}
