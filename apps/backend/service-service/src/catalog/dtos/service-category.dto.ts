import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayUnique,
  IsArray,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateIf,
} from 'class-validator';

import { CatalogStatus } from '../enums';

export class CreateServiceCategoryDto {
  @ApiProperty({ maxLength: 120 }) @IsString() @IsNotEmpty() @MaxLength(120) name!: string;
  @ApiProperty({ maxLength: 40 }) @IsString() @IsNotEmpty() @MaxLength(40) code!: string;
  @ApiPropertyOptional({ maxLength: 500 })
  @ValidateIf((_object, value) => value !== undefined)
  @IsString()
  @MaxLength(500)
  description?: string;
  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  branchIds?: string[];
  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;
}

export class UpdateServiceCategoryDto {
  @ApiPropertyOptional({ maxLength: 120 })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  name?: string;
  @ApiPropertyOptional({ maxLength: 40 })
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(40)
  code?: string;
  @ApiPropertyOptional({ maxLength: 500 })
  @ValidateIf((_object, value) => value !== undefined)
  @IsString()
  @MaxLength(500)
  description?: string;
  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  branchIds?: string[];
  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;
}
