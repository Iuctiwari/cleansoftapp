import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsMongoId,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
  ValidateIf,
} from 'class-validator';

export class OrderItemDto {
  @ApiProperty({ description: 'Catalog item-category identifier.' })
  @IsMongoId()
  itemCategoryId!: string;

  @ApiProperty({ description: 'Catalog service identifier.' })
  @IsMongoId()
  serviceId!: string;

  @ApiPropertyOptional({
    description: 'Unit count for non-weight catalog pricing types; validated against the quote.',
    minimum: 0.000001,
  })
  @ValidateIf((item: OrderItemDto) => item.weight === undefined || item.quantity !== undefined)
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 6 })
  @Min(0.000001)
  quantity?: number;

  @ApiPropertyOptional({
    description: 'Measured weight for PerKg catalog pricing; validated against the quote.',
    minimum: 0.000001,
  })
  @ValidateIf((item: OrderItemDto) => item.quantity === undefined || item.weight !== undefined)
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 6 })
  @Min(0.000001)
  weight?: number;

  @ApiPropertyOptional({
    default: 0,
    minimum: 0,
    description: 'Requested absolute line discount; the backend validates and applies it.',
  })
  @IsOptional()
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0)
  discount: number = 0;

  @ApiPropertyOptional({
    default: 0,
    deprecated: true,
    minimum: 0,
    description: 'Ignored. Line tax is calculated from the authoritative catalog quote.',
  })
  @IsOptional()
  @IsNumber({ allowInfinity: false, allowNaN: false, maxDecimalPlaces: 2 })
  @Min(0)
  tax: number = 0;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  notes?: string;
}
