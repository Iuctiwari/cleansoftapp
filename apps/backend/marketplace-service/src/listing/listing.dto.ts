import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform, Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  ArrayUnique,
  IsBoolean,
  IsIn,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  Max,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';

import {
  SERVICE_MODES,
  SHOP_CATEGORIES,
  type ServiceMode,
  type ShopCategory,
} from '../platform/marketplace.types';

const CLOCK = /^([01]\d|2[0-3]):[0-5]\d$/;

export class OpeningHoursDto {
  @ApiProperty({ description: '0 = Sunday … 6 = Saturday', minimum: 0, maximum: 6 })
  @IsInt()
  @Min(0)
  @Max(6)
  day!: number;

  @ApiProperty({ description: 'Closed all day' })
  @IsBoolean()
  closed!: boolean;

  @ApiPropertyOptional({ description: 'Opening time, 24-hour HH:mm', example: '09:00' })
  @IsOptional()
  @Matches(CLOCK, { message: 'open must be HH:mm' })
  open?: string;

  @ApiPropertyOptional({ description: 'Closing time, 24-hour HH:mm', example: '20:30' })
  @IsOptional()
  @Matches(CLOCK, { message: 'close must be HH:mm' })
  close?: string;
}

/** The shop's public listing for one branch — a full replace on every save. */
export class UpsertShopListingDto {
  @ApiProperty({
    description: 'Shop number, building, street',
    example: 'Shop 4, Sunrise Plaza, SV Road',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  streetAddress!: string;

  @ApiPropertyOptional({ description: 'Area / locality', example: 'Andheri West' })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  area?: string;

  @ApiPropertyOptional({ example: 'Opposite Andheri station' })
  @IsOptional()
  @IsString()
  @MaxLength(120)
  landmark?: string;

  @ApiProperty({ example: 'Mumbai' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  city!: string;

  @ApiProperty({ example: 'Maharashtra' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(80)
  state!: string;

  @ApiProperty({ description: '6-digit PIN code', example: '400058' })
  @Matches(/^[1-9]\d{5}$/, { message: 'postalCode must be a 6-digit PIN code' })
  postalCode!: string;

  @ApiProperty({ description: 'GPS latitude of the shop pin', example: 19.1197 })
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ description: 'GPS longitude of the shop pin', example: 72.8468 })
  @IsLongitude()
  longitude!: number;

  @ApiPropertyOptional({
    description: 'Number customers call to book. Leave empty to show the owner phone instead.',
    example: '9876543210',
  })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  bookingPhone?: string;

  @ApiProperty({ enum: SERVICE_MODES, isArray: true, example: ['visit_shop', 'pickup_drop'] })
  @ArrayMinSize(1, { message: 'Choose at least one way you serve customers' })
  @ArrayUnique()
  @IsIn(SERVICE_MODES, { each: true })
  serviceModes!: ServiceMode[];

  @ApiPropertyOptional({
    description: 'How far you travel for home service / pickup, in km',
    minimum: 1,
    maximum: 50,
    default: 5,
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  serviceRadiusKm?: number;

  @ApiProperty({ type: [OpeningHoursDto], description: 'Exactly 7 entries, one per day' })
  @ArrayMinSize(7)
  @ArrayMaxSize(7)
  @ValidateNested({ each: true })
  @Type(() => OpeningHoursDto)
  openingHours!: OpeningHoursDto[];

  @ApiPropertyOptional({ description: 'Short description shown to customers', maxLength: 300 })
  @IsOptional()
  @IsString()
  @MaxLength(300)
  about?: string;

  @ApiPropertyOptional({ description: 'Show this shop to customers', default: true })
  @IsOptional()
  @IsBoolean()
  isListed?: boolean;
}

const toBoolean = ({ value }: { value: unknown }): boolean =>
  value === true || value === 'true' || value === '1';

export class ShopSearchQueryDto {
  @ApiPropertyOptional({
    description: 'Search from this saved address (default: my default address)',
  })
  @IsOptional()
  @IsString()
  addressId?: string;

  @ApiPropertyOptional({ description: 'Search from the current GPS position instead' })
  @IsOptional()
  @Type(() => Number)
  @IsLatitude()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsLongitude()
  longitude?: number;

  @ApiPropertyOptional({ enum: SHOP_CATEGORIES })
  @IsOptional()
  @IsIn(SHOP_CATEGORIES)
  category?: ShopCategory;

  @ApiPropertyOptional({ enum: SERVICE_MODES, description: 'Only shops that serve this way' })
  @IsOptional()
  @IsIn(SERVICE_MODES)
  mode?: ServiceMode;

  @ApiPropertyOptional({ description: 'Only shops open right now' })
  @IsOptional()
  @Transform(toBoolean)
  @IsBoolean()
  openNow?: boolean;

  @ApiPropertyOptional({ description: 'Search radius in km', minimum: 1, maximum: 50, default: 10 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  radiusKm?: number;

  @ApiPropertyOptional({ description: 'Shop name contains' })
  @IsOptional()
  @IsString()
  @MaxLength(60)
  q?: string;

  @ApiPropertyOptional({ minimum: 1, default: 1 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number;

  @ApiPropertyOptional({ minimum: 1, maximum: 50, default: 20 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;
}

export class ShopDetailQueryDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  addressId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsLatitude()
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsLongitude()
  longitude?: number;
}
