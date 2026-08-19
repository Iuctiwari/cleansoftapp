import { ApiPropertyOptional } from '@nestjs/swagger';
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
  ValidateIf,
} from 'class-validator';

import { CatalogStatus, PricingType } from '../enums';

export class UpdateServiceDto {
  @ApiPropertyOptional({ nullable: true }) @IsOptional() @IsMongoId() categoryId?: string;
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
  @ApiPropertyOptional({ enum: PricingType })
  @IsOptional()
  @IsEnum(PricingType)
  pricingType?: PricingType;
  @ApiPropertyOptional({ minimum: 0 }) @IsOptional() @IsInt() @Min(0) estimatedTimeMins?: number;
  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;
  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  branchIds?: string[];
}
