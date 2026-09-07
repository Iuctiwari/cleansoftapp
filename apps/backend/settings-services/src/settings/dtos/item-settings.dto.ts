import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

import { CatalogStatus, UnitType } from '../enums';

function normalizeUnitType(val: unknown): UnitType | unknown {
  if (typeof val !== 'string') return val;
  const clean = val.toLowerCase().replace(/[^a-z]/g, '');
  switch (clean) {
    case 'piece':
    case 'pc':
    case 'pcs':
      return UnitType.PIECE;
    case 'kg':
    case 'kilogram':
      return UnitType.KG;
    case 'pair':
    case 'pairs':
      return UnitType.PAIR;
    case 'hour':
    case 'hours':
    case 'hr':
    case 'hrs':
      return UnitType.HOUR;
    default:
      return val;
  }
}

export class CreateItemSettingsDto {
  @ApiProperty({ description: 'Item Name', maxLength: 120, example: 'Shirt' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name!: string;

  @ApiProperty({ description: 'Unique Item Code within Tenant', maxLength: 40, example: 'SHIRT' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  code!: string;

  @ApiProperty({ enum: UnitType, example: UnitType.PIECE })
  @Transform(({ value }) => normalizeUnitType(value))
  @IsEnum(UnitType)
  unitType!: UnitType;

  @ApiPropertyOptional({ description: 'Item Description', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ description: 'Category Label/Group', maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  category?: string;

  @ApiPropertyOptional({ description: 'Catalog Group Codes', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  catalogGroupCodes?: string[];

  @ApiPropertyOptional({ description: 'Allowed branch IDs (empty = all branches)', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  branchIds?: string[];

  @ApiPropertyOptional({ enum: CatalogStatus, default: CatalogStatus.ACTIVE })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;

  @ApiPropertyOptional({ description: 'Initial base price when creating an item', minimum: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  basePrice?: number;

  @ApiPropertyOptional({ description: 'Initial mapped service IDs', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  serviceIds?: string[];
}

export class UpdateItemSettingsDto {
  @ApiPropertyOptional({ description: 'Item Name', maxLength: 120 })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string;

  @ApiPropertyOptional({ enum: UnitType })
  @Transform(({ value }) => normalizeUnitType(value))
  @IsOptional()
  @IsEnum(UnitType)
  unitType?: UnitType;

  @ApiPropertyOptional({ description: 'Item Description', maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional({ description: 'Category Label/Group', maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  category?: string;

  @ApiPropertyOptional({ description: 'Catalog Group Codes', type: [String] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  catalogGroupCodes?: string[];

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
