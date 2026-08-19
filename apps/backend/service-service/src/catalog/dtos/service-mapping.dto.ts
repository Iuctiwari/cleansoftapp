import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEnum, IsMongoId, IsOptional, IsString } from 'class-validator';

import { CatalogStatus } from '../enums';

export class CreateServiceMappingDto {
  @ApiProperty() @IsMongoId() itemCategoryId!: string;
  @ApiProperty() @IsMongoId() serviceId!: string;
  @ApiPropertyOptional({ description: 'Omit for a tenant-wide mapping.' })
  @IsOptional()
  @IsString()
  branchId?: string;
  @ApiPropertyOptional({ description: 'True when this mapping still needs an effective price.' })
  @IsOptional()
  @IsBoolean()
  requiresPricingConfiguration?: boolean;
}

export class UpdateServiceMappingDto {
  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;
}

export class ServiceMappingQueryDto {
  @ApiPropertyOptional() @IsOptional() @IsMongoId() itemCategoryId?: string;
  @ApiPropertyOptional() @IsOptional() @IsMongoId() serviceId?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() branchId?: string;
  @ApiPropertyOptional({ enum: CatalogStatus })
  @IsOptional()
  @IsEnum(CatalogStatus)
  status?: CatalogStatus;
}
