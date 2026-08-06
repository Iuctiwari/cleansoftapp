import {
  IsBoolean,
  IsEmail,
  IsEnum,
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

import type { TenantBusinessType, TenantStatus, BranchStatus } from './tenant.types';

export const BUSINESS_TYPE_VALUES = [
  'laundry',
  'dry_cleaning',
  'tailoring',
  'shoe_cleaning',
  'appliance_repair',
  'mobile_repair',
  'vehicle_wash',
  'salon',
  'general',
  'custom',
] as const;

// ─── Request DTOs ─────────────────────────────────────────────────────────────

export class RegisterTenantDto {
  @ApiProperty({
    description: 'Legal or trading name of the business',
    example: 'Ahmed Laundry & Cleaners',
    maxLength: 120,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  businessName!: string;

  @ApiProperty({
    description: 'Primary business type — determines the default service catalog',
    enum: BUSINESS_TYPE_VALUES,
    example: 'laundry',
  })
  @IsEnum(BUSINESS_TYPE_VALUES)
  businessType!: TenantBusinessType;

  @ApiProperty({
    description: 'Full name of the business owner',
    example: 'Ahmed Al-Rashid',
    maxLength: 120,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(120)
  ownerName!: string;

  @ApiProperty({
    description: 'Owner email address — used for login and notifications',
    example: 'ahmed@laundry.com',
    maxLength: 160,
  })
  @IsEmail()
  @MaxLength(160)
  email!: string;

  @ApiProperty({
    description: 'Owner mobile number (7–15 digits, optional leading +)',
    example: '+971501234567',
  })
  @IsString()
  @Matches(/^\+?[0-9]{7,15}$/, {
    message: 'mobileNumber must be a valid phone number (7–15 digits, optional leading +)',
  })
  mobileNumber!: string;

  @ApiProperty({
    description:
      'Account password (min 8 chars, requires upper/lowercase, digit, and special char)',
    minLength: 8,
    maxLength: 256,
    example: 'Str0ng!Pass',
  })
  @IsString()
  @MinLength(8)
  @MaxLength(256)
  password!: string;

  @ApiProperty({
    description: 'Must be true — the user has accepted the Terms of Service',
    example: true,
  })
  @IsBoolean()
  agreedToTerms!: boolean;
}

// ─── Response DTOs ────────────────────────────────────────────────────────────

export class RegisterTenantResponseDto {
  @ApiProperty({ description: 'Unique tenant identifier', example: 'a1b2c3d4e5f6a1b2c3d4e5f6' })
  tenantId!: string;

  @ApiProperty({ description: 'URL-safe slug for the tenant', example: 'ahmed-laundry-cleaners' })
  slug!: string;

  @ApiProperty({ description: 'Unique ID of the created owner user account' })
  ownerUserId!: string;

  @ApiProperty({ description: 'Business name as stored', example: 'Ahmed Laundry & Cleaners' })
  businessName!: string;

  @ApiProperty({
    description: 'Human-readable result message',
    example: 'Account created successfully',
  })
  message!: string;
}

export class TenantProfileDto {
  @ApiProperty() tenantId!: string;
  @ApiProperty() slug!: string;
  @ApiProperty() businessName!: string;
  @ApiProperty({ enum: BUSINESS_TYPE_VALUES }) businessType!: TenantBusinessType;
  @ApiProperty() ownerName!: string;
  @ApiProperty() ownerEmail!: string;
  @ApiProperty() ownerPhone!: string;
  @ApiProperty() taxEnabled!: boolean;
  @ApiProperty() defaultTaxPct!: number;
  @ApiProperty({ enum: ['PendingVerification', 'Active', 'Suspended', 'Cancelled'] })
  status!: TenantStatus;
  @ApiProperty() createdAt!: string;
  @ApiProperty() updatedAt!: string;
}

export class BranchDto {
  @ApiProperty() branchId!: string;
  @ApiProperty() tenantId!: string;
  @ApiProperty() branchName!: string;
  @ApiProperty() streetAddress!: string;
  @ApiProperty() city!: string;
  @ApiProperty() state!: string;
  @ApiProperty() country!: string;
  @ApiProperty() postalCode!: string;
  @ApiProperty() phone!: string;
  @ApiProperty() email!: string;
  @ApiProperty() isHeadOffice!: boolean;
  @ApiProperty({ enum: ['active', 'inactive', 'closed'] }) status!: BranchStatus;
  @ApiProperty() createdAt!: string;
  @ApiProperty() updatedAt!: string;
}
