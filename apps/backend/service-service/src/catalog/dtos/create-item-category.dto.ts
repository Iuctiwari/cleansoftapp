import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayUnique,
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import { CatalogStatus, UnitType } from '../enums';

export class CreateItemCategoryDto {
  @ApiProperty({ maxLength: 120 }) @IsString() @IsNotEmpty() @MaxLength(120) name!: string;
  @ApiProperty({ maxLength: 40 }) @IsString() @IsNotEmpty() @MaxLength(40) code!: string;
  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
  @ApiPropertyOptional({ maxLength: 120 })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  category?: string;
  @ApiProperty({ enum: UnitType }) @IsEnum(UnitType) unitType!: UnitType;
  @ApiPropertyOptional({ enum: CatalogStatus, default: CatalogStatus.ACTIVE })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;
  @ApiPropertyOptional({ type: [String], description: 'Empty means all tenant branches.' })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  branchIds?: string[];
}
