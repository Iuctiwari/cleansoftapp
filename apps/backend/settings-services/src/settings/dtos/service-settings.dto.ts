import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

import { CatalogStatus, PricingType } from '../enums';

function normalizePricingType(val: unknown): PricingType {
  if (typeof val !== 'string') return val as PricingType;
  const clean = val.toLowerCase().replace(/[^a-z]/g, '');
  switch (clean) {
    case 'peritem':
    case 'item':
      return PricingType.PER_ITEM;
    case 'perkg':
    case 'kg':
      return PricingType.PER_KG;
    case 'perpair':
    case 'pair':
      return PricingType.PER_PAIR;
    case 'perhour':
    case 'hour':
      return PricingType.PER_HOUR;
    case 'fixed':
      return PricingType.FIXED;
    case 'custom':
      return PricingType.CUSTOM;
    default:
      return val as PricingType;
  }
}

export class CreateServiceSettingsDto {
  @ApiProperty({ description: 'Service Name', maxLength: 120, example: 'Dry Cleaning' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  serviceName!: string;

  @ApiProperty({
    description: 'Unique Service Code within Tenant',
    maxLength: 40,
    example: 'DRY_CLEAN',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  code!: string;

  @ApiProperty({ enum: PricingType, example: PricingType.PER_ITEM })
  @Transform(({ value }) => normalizePricingType(value))
  @IsEnum(PricingType)
  pricingType!: PricingType;

  @ApiPropertyOptional({ description: 'Service Description', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ description: 'Optional Category ID' })
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiPropertyOptional({ description: 'Estimated turnaround time in minutes', minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  estimatedTimeMins?: number;

  @ApiPropertyOptional({ description: 'Allowed branch IDs (empty = all branches)', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  branchIds?: string[];

  @ApiPropertyOptional({ enum: CatalogStatus, default: CatalogStatus.ACTIVE })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;

  @ApiPropertyOptional({ description: 'Initial base price when creating a service', minimum: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  basePrice?: number;

  @ApiPropertyOptional({ description: 'Initial mapped item category IDs', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  itemCategoryIds?: string[];
}

export class UpdateServiceSettingsDto {
  @ApiPropertyOptional({ description: 'Service Name', maxLength: 120 })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  serviceName?: string;

  @ApiPropertyOptional({ enum: PricingType })
  @Transform(({ value }) => normalizePricingType(value))
  @IsOptional()
  @IsEnum(PricingType)
  pricingType?: PricingType;

  @ApiPropertyOptional({ description: 'Service Description', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ description: 'Category ID' })
  @IsOptional()
  @IsString()
  categoryId?: string;

  @ApiPropertyOptional({ description: 'Estimated turnaround time in minutes', minimum: 0 })
  @IsOptional()
  @IsInt()
  @Min(0)
  estimatedTimeMins?: number;

  @ApiPropertyOptional({ description: 'Allowed branch IDs', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  branchIds?: string[];

  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;
}
