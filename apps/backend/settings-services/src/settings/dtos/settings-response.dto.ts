import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CatalogStatus, PricingType, UnitType } from '../enums';

export class SettingsServiceResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  tenantId!: string;

  @ApiProperty()
  serviceName!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  code!: string;

  @ApiProperty({ enum: PricingType })
  pricingType!: PricingType;

  @ApiPropertyOptional()
  description?: string;

  @ApiPropertyOptional()
  categoryId?: string;

  @ApiPropertyOptional()
  estimatedTimeMins?: number;

  @ApiProperty({ type: [String] })
  branchIds!: string[];

  @ApiProperty({ enum: CatalogStatus })
  status!: CatalogStatus;

  @ApiPropertyOptional({ type: [String] })
  itemCategoryIds?: string[];

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;

  @ApiProperty()
  version!: number;
}

export class SettingsItemResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  tenantId!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  code!: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiPropertyOptional()
  category?: string;

  @ApiProperty({ type: [String] })
  catalogGroupCodes!: string[];

  @ApiProperty({ enum: UnitType })
  unitType!: UnitType;

  @ApiProperty({ type: [String] })
  branchIds!: string[];

  @ApiProperty({ enum: CatalogStatus })
  status!: CatalogStatus;

  @ApiPropertyOptional({ type: [String] })
  serviceIds?: string[];

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;

  @ApiProperty()
  version!: number;
}

export class SettingsCategoryResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  tenantId!: string;

  @ApiProperty()
  name!: string;

  @ApiProperty()
  code!: string;

  @ApiPropertyOptional()
  description?: string;

  @ApiProperty({ type: [String] })
  branchIds!: string[];

  @ApiProperty({ enum: CatalogStatus })
  status!: CatalogStatus;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  updatedAt!: Date;

  @ApiProperty()
  version!: number;
}

export class SettingsPricingResponseDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  tenantId!: string;

  @ApiProperty()
  serviceId!: string;

  @ApiProperty()
  itemCategoryId!: string;

  @ApiPropertyOptional()
  branchId!: string | null;

  @ApiProperty({ enum: PricingType })
  pricingType!: PricingType;

  @ApiProperty()
  basePrice!: number;

  @ApiProperty()
  taxPct!: number;

  @ApiProperty()
  effectiveFrom!: Date;

  @ApiPropertyOptional()
  effectiveTo?: Date;

  @ApiProperty({ enum: CatalogStatus })
  status!: CatalogStatus;

  @ApiProperty()
  createdAt!: Date;

  @ApiProperty()
  version!: number;
}

export class BusinessSettingsSummaryResponseDto {
  @ApiProperty()
  tenantId!: string;

  @ApiProperty()
  totalServices!: number;

  @ApiProperty()
  totalActiveServices!: number;

  @ApiProperty()
  totalItems!: number;

  @ApiProperty()
  totalActiveItems!: number;

  @ApiProperty()
  totalCategories!: number;

  @ApiProperty()
  totalActiveCategories!: number;

  @ApiProperty()
  totalActivePricing!: number;

  @ApiProperty({ type: [SettingsServiceResponseDto] })
  services!: SettingsServiceResponseDto[];

  @ApiProperty({ type: [SettingsItemResponseDto] })
  items!: SettingsItemResponseDto[];

  @ApiProperty({ type: [SettingsCategoryResponseDto] })
  categories!: SettingsCategoryResponseDto[];

  @ApiProperty({ type: [SettingsPricingResponseDto] })
  pricing!: SettingsPricingResponseDto[];
}
