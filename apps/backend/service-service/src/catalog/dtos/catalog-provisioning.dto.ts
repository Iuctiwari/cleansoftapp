import { ApiProperty } from '@nestjs/swagger';
import { ArrayNotEmpty, ArrayUnique, IsArray, IsIn, IsMongoId } from 'class-validator';

import { CATALOG_BUSINESS_TYPES, type CatalogBusinessType } from '../catalog.types';

export class ProvisionCatalogDto {
  @ApiProperty() @IsMongoId() tenantId!: string;
  @ApiProperty() @IsMongoId() actorId!: string;
  @ApiProperty({ enum: CATALOG_BUSINESS_TYPES, isArray: true })
  @IsArray()
  @ArrayNotEmpty()
  @ArrayUnique()
  @IsIn(CATALOG_BUSINESS_TYPES, { each: true })
  businessTypes!: CatalogBusinessType[];
}

export class CatalogProvisioningResponseDto {
  @ApiProperty() tenantId!: string;
  @ApiProperty({ type: [String] }) appliedTemplates!: string[];
  @ApiProperty({ type: [String] }) missingTemplates!: string[];
  @ApiProperty() createdItems!: number;
  @ApiProperty() reusedItems!: number;
  @ApiProperty() createdServices!: number;
  @ApiProperty() reusedServices!: number;
  @ApiProperty() createdMappings!: number;
  @ApiProperty() reusedMappings!: number;
  @ApiProperty() createdPrices!: number;
  @ApiProperty() preservedPrices!: number;
  @ApiProperty() pricingConfigurationRequired!: number;
}
