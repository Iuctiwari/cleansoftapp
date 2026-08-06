import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';

import type { AuthLoginContext } from './auth.types';

export class AuthLoginDto {
  @ApiProperty({
    enum: ['platform', 'tenant'],
    example: 'tenant',
    description: 'Authentication scope used to resolve the account.',
  })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({
    example: 'owner@alpha.nexoraa.local',
    description: 'Email address or mobile number used to sign in.',
    maxLength: 160,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiProperty({
    example: 'Tenant#123',
    description: 'Raw account password.',
    maxLength: 256,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  password!: string;

  @ApiPropertyOptional({
    example: 'alpha',
    description: 'Tenant slug required when context is tenant.',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;

  @ApiPropertyOptional({
    example: 'main',
    description: 'Optional tenant branch code to pin the login context.',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  branchCode?: string;

  @ApiPropertyOptional({
    example: 'device-android-01',
    description: 'Stable client-side device identifier.',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;

  @ApiPropertyOptional({
    example: 'Pixel 8 Pro',
    description: 'Human-readable device name.',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceName?: string;
}

export class AuthRefreshDto {
  @ApiProperty({
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh-token',
    description: 'Opaque refresh token previously issued by the login endpoint.',
  })
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}

export class AuthForgotPasswordDto {
  @ApiProperty({
    enum: ['platform', 'tenant'],
    example: 'tenant',
    description: 'Authentication scope used to find the account.',
  })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({
    example: 'owner@alpha.nexoraa.local',
    maxLength: 160,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiPropertyOptional({
    example: 'alpha',
    description: 'Tenant slug required for tenant reset flows.',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;
}

export class AuthResetPasswordDto {
  @ApiProperty({ enum: ['platform', 'tenant'], example: 'tenant' })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({ example: 'owner@alpha.nexoraa.local', maxLength: 160 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiPropertyOptional({ example: 'alpha', maxLength: 64 })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;

  @ApiProperty({
    example: '482901',
    description: 'Six-digit one-time password delivered during forgot-password.',
    pattern: '^\\d{6}$',
  })
  @Matches(/^\d{6}$/)
  otp!: string;

  @ApiProperty({
    example: 'Tenant#456',
    minLength: 8,
    maxLength: 256,
    description: 'New password that must satisfy the platform password policy.',
  })
  @IsString()
  @MinLength(8)
  @MaxLength(256)
  newPassword!: string;
}

export class AuthChangePasswordDto {
  @ApiProperty({ example: 'Tenant#123', description: 'Current password for the session user.' })
  @IsString()
  @IsNotEmpty()
  currentPassword!: string;

  @ApiProperty({
    example: 'Tenant#456',
    minLength: 8,
    maxLength: 256,
    description: 'Replacement password that must satisfy the platform password policy.',
  })
  @IsString()
  @MinLength(8)
  @MaxLength(256)
  newPassword!: string;
}
