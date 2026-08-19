import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  ArrayUnique,
  IsArray,
  IsEnum,
  IsInt,
  IsMongoId,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

import { CatalogStatus, PricingType } from '../enums';

export class CreateServiceDto {
  @ApiPropertyOptional() @IsOptional() @IsMongoId() categoryId?: string;
  @ApiProperty({ maxLength: 120 }) @IsString() @IsNotEmpty() @MaxLength(120) name!: string;
  @ApiProperty({ maxLength: 40 }) @IsString() @IsNotEmpty() @MaxLength(40) code!: string;
  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;
  @ApiProperty({ enum: PricingType }) @IsEnum(PricingType) pricingType!: PricingType;
  @ApiPropertyOptional({ minimum: 0 }) @IsOptional() @IsInt() @Min(0) estimatedTimeMins?: number;
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
