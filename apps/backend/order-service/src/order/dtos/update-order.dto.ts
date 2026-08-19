import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsNumber,
  IsOptional,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

import { OrderItemDto } from './order-item.dto';

export class UpdateOrderDto {
  @ApiPropertyOptional({ type: [OrderItemDto], minItems: 1 })
  @IsOptional()
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => OrderItemDto)
  items?: OrderItemDto[];

  @ApiPropertyOptional({
    minimum: 0,
    description: 'Requested absolute order discount; validated and applied by the backend.',
  })
  @IsOptional()
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0)
  discount?: number;

  @ApiPropertyOptional({
    maximum: 100,
    minimum: 0,
    description: 'Percentage order discount. Mutually exclusive with an absolute discount.',
  })
  @IsOptional()
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0)
  @Max(100)
  discountPercentage?: number;

  @ApiPropertyOptional({
    deprecated: true,
    minimum: 0,
    description: 'Ignored. Tax remains backend-controlled.',
  })
  @IsOptional()
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0)
  tax?: number;

  @ApiPropertyOptional({ format: 'date-time', nullable: true, type: String })
  @IsOptional()
  @IsDateString({ strict: true })
  expectedDeliveryDate?: string;
}
