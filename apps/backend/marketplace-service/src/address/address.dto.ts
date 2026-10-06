import { ApiProperty, ApiPropertyOptional, PartialType } from '@nestjs/swagger';
import {
  IsBoolean,
  IsIn,
  IsLatitude,
  IsLongitude,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';

import { ADDRESS_LABELS, type AddressLabel } from '../platform/marketplace.types';

export class CreateAddressDto {
  @ApiProperty({ enum: ADDRESS_LABELS, example: 'Home' })
  @IsIn(ADDRESS_LABELS)
  label!: AddressLabel;

  @ApiPropertyOptional({ description: 'Defaults to the account name', maxLength: 80 })
  @IsOptional()
  @IsString()
  @MaxLength(80)
  contactName?: string;

  @ApiPropertyOptional({ description: 'Defaults to the account mobile number', maxLength: 20 })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  contactPhone?: string;

  @ApiProperty({ description: 'House / flat / floor', example: 'Flat 302, Sai Residency' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  houseFlat!: string;

  @ApiProperty({ description: 'Street, area or locality', example: 'Lokhandwala, Andheri West' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  streetArea!: string;

  @ApiPropertyOptional({ example: 'Near Infiniti Mall' })
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

  @ApiProperty({ description: '6-digit PIN code', example: '400053' })
  @Matches(/^[1-9]\d{5}$/, { message: 'pincode must be a 6-digit PIN code' })
  pincode!: string;

  @ApiProperty({ description: 'GPS latitude of the address pin', example: 19.1364 })
  @IsLatitude()
  latitude!: number;

  @ApiProperty({ description: 'GPS longitude of the address pin', example: 72.8296 })
  @IsLongitude()
  longitude!: number;

  @ApiPropertyOptional({ description: 'Make this the default address' })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}

export class UpdateAddressDto extends PartialType(CreateAddressDto) {}
