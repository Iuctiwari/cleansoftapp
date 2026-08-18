import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsEnum,
  IsIn,
  IsMongoId,
  IsNumber,
  IsOptional,
  IsString,
  Max,
  Min,
} from 'class-validator';

import { CatalogStatus } from '../enums';

export class CreateServicePricingDto {
  @ApiProperty() @IsMongoId() itemCategoryId!: string;
  @ApiPropertyOptional({ description: 'Omit for tenant-wide pricing.' })
  @IsOptional()
  @IsString()
  branchId?: string;
  @ApiProperty({ minimum: 0 }) @IsNumber({ maxDecimalPlaces: 2 }) @Min(0) basePrice!: number;
  @ApiPropertyOptional({ default: 0, minimum: 0, maximum: 100 })
  @IsOptional()
  @IsNumber({ maxDecimalPlaces: 4 })
  @Min(0)
  @Max(100)
  taxPct?: number;
  @ApiProperty() @IsDateString() effectiveFrom!: string;
  @ApiPropertyOptional() @IsOptional() @IsDateString() effectiveTo?: string;
  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;
}

export class ServicePricingQueryDto {
  @ApiPropertyOptional() @IsOptional() @IsMongoId() itemCategoryId?: string;
}

export class UpdateServicePricingDto {
  @ApiPropertyOptional({
    description: 'Close this immutable pricing version at the specified UTC timestamp.',
  })
  @IsOptional()
  @IsDateString()
  effectiveTo?: string;

  @ApiPropertyOptional({
    description: 'Deactivate this pricing version. Reactivation requires a new pricing version.',
    enum: [CatalogStatus.INACTIVE],
  })
  @IsOptional()
  @IsEnum(CatalogStatus)
  @IsIn([CatalogStatus.INACTIVE])
  status?: CatalogStatus.INACTIVE;
}
