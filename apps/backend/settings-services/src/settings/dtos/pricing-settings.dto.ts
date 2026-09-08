import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';

import { CatalogStatus } from '../enums';

export class UpdatePricingSettingsDto {
  @ApiProperty({ description: 'Base Price', minimum: 0, example: 50.0 })
  @IsNumber()
  @Min(0)
  basePrice!: number;

  @ApiPropertyOptional({
    description: 'Tax percentage (0-100)',
    minimum: 0,
    maximum: 100,
    default: 0,
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  @Max(100)
  taxPct?: number;

  @ApiPropertyOptional({ description: 'Effective From ISO date' })
  @IsOptional()
  @IsDateString()
  effectiveFrom?: string;

  @ApiPropertyOptional({ description: 'Effective To ISO date' })
  @IsOptional()
  @IsDateString()
  effectiveTo?: string;

  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;

  @ApiPropertyOptional({ description: 'Branch ID (null/omitted for tenant-wide)' })
  @IsOptional()
  @IsString()
  branchId?: string;
}
