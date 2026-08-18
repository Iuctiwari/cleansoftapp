import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { CatalogStatus, PricingType, UnitType } from '../enums';

export class CatalogBaseResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() tenantId!: string;
  @ApiProperty({ enum: CatalogStatus }) status!: CatalogStatus;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
  @ApiProperty() version!: number;
}

export class ItemCategoryResponseDto extends CatalogBaseResponseDto {
  @ApiProperty() name!: string;
  @ApiProperty() code!: string;
  @ApiPropertyOptional() description?: string;
  @ApiPropertyOptional() category?: string;
  @ApiProperty({ type: [String] }) catalogGroupCodes!: string[];
  @ApiProperty({ enum: UnitType }) unitType!: UnitType;
  @ApiProperty({ type: [String] }) branchIds!: string[];
  @ApiPropertyOptional({ type: [String] }) serviceIds?: string[];
}

export class ServiceResponseDto extends CatalogBaseResponseDto {
  @ApiPropertyOptional() categoryId?: string;
  @ApiProperty() serviceName!: string;
  @ApiProperty({ description: 'Compatibility alias of serviceName.' }) name!: string;
  @ApiProperty() code!: string;
  @ApiPropertyOptional() description?: string;
  @ApiProperty({ enum: PricingType }) pricingType!: PricingType;
  @ApiPropertyOptional() estimatedTimeMins?: number;
  @ApiProperty({ type: [String] }) branchIds!: string[];
  @ApiPropertyOptional({ type: [String] }) itemCategoryIds?: string[];
  @ApiPropertyOptional({ type: () => [ServicePricingResponseDto] })
  currentPricing?: ServicePricingResponseDto[];
}

export class ServiceCategoryResponseDto extends CatalogBaseResponseDto {
  @ApiProperty() name!: string;
  @ApiProperty() code!: string;
  @ApiPropertyOptional() description?: string;
  @ApiProperty({ type: [String] }) branchIds!: string[];
}

export class ServiceMappingResponseDto extends CatalogBaseResponseDto {
  @ApiProperty() itemCategoryId!: string;
  @ApiProperty() serviceId!: string;
  @ApiPropertyOptional({ nullable: true }) branchId!: string | null;
  @ApiProperty({ enum: PricingType }) pricingType!: PricingType;
  @ApiProperty() requiresPricingConfiguration!: boolean;
}

export class ServicePricingResponseDto extends CatalogBaseResponseDto {
  @ApiProperty() itemCategoryId!: string;
  @ApiProperty() serviceId!: string;
  @ApiPropertyOptional({ nullable: true }) branchId!: string | null;
  @ApiProperty({ enum: PricingType }) pricingType!: PricingType;
  @ApiProperty() basePrice!: number;
  @ApiProperty() taxPct!: number;
  @ApiProperty() effectiveFrom!: Date;
  @ApiPropertyOptional() effectiveTo?: Date;
}

export class QuoteResponseDto {
  @ApiProperty() serviceId!: string;
  @ApiProperty() itemCategoryId!: string;
  @ApiProperty() branchId!: string;
  @ApiProperty() serviceMappingId!: string;
  @ApiProperty() servicePricingId!: string;
  @ApiProperty() version!: number;
  @ApiProperty({ enum: PricingType }) pricingType!: PricingType;
  @ApiProperty() basePrice!: number;
  @ApiProperty() unitPrice!: number;
  @ApiProperty() taxPct!: number;
  @ApiPropertyOptional() quantity?: number;
  @ApiPropertyOptional() weight?: number;
  @ApiPropertyOptional() subtotal?: number;
  @ApiPropertyOptional() lineAmount?: number;
  @ApiProperty() effectiveFrom!: Date;
  @ApiPropertyOptional() effectiveTo?: Date;
}

export class ItemCategoryPageResponseDto {
  @ApiProperty({ type: [ItemCategoryResponseDto] }) items!: ItemCategoryResponseDto[];
  @ApiProperty() total!: number;
  @ApiProperty() page!: number;
  @ApiProperty() limit!: number;
}

export class ServicePageResponseDto {
  @ApiProperty({ type: [ServiceResponseDto] }) items!: ServiceResponseDto[];
  @ApiProperty() total!: number;
  @ApiProperty() page!: number;
  @ApiProperty() limit!: number;
}

export class ServiceCategoryPageResponseDto {
  @ApiProperty({ type: [ServiceCategoryResponseDto] }) items!: ServiceCategoryResponseDto[];
  @ApiProperty() total!: number;
  @ApiProperty() page!: number;
  @ApiProperty() limit!: number;
}

export class CatalogErrorResponseDto {
  @ApiProperty() statusCode!: number;
  @ApiProperty() code!: string;
  @ApiProperty() message!: string;
  @ApiProperty() timestamp!: string;
  @ApiProperty() path!: string;
  @ApiProperty() method!: string;
}
