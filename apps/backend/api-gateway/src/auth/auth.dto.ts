import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MaxLength,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import type { AuthLoginContext } from './auth.types';

export class AuthLoginDto {
  @ApiProperty({
    description: 'Account scope to authenticate against.',
    enum: ['platform', 'tenant'],
    example: 'tenant',
  })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({
    description: 'Email address, mobile number, or username used to identify the account.',
    example: 'owner@example.com',
    maxLength: 160,
    minLength: 1,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiProperty({
    description: 'Account password.',
    example: 'SecurePassword1!',
    format: 'password',
    maxLength: 256,
    minLength: 1,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  password!: string;

  @ApiPropertyOptional({
    description: 'Tenant slug. Required when context is tenant.',
    example: 'acme-cleaning',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;

  @ApiPropertyOptional({
    description: 'Branch code to select for the authenticated tenant session.',
    example: 'BLR-01',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  branchCode?: string;

  @ApiPropertyOptional({
    description: 'Client-provided stable device identifier.',
    example: 'device-7f8a2c',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;

  @ApiPropertyOptional({
    description: 'Human-readable device name shown in session information.',
    example: 'Chrome on Windows',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceName?: string;
}

export class AuthRefreshDto {
  @ApiProperty({
    description: 'Refresh token previously issued by the login or refresh endpoint.',
    example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh-token',
    minLength: 1,
  })
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}

export class AuthForgotPasswordDto {
  @ApiProperty({
    description: 'Account scope in which to locate the identity.',
    enum: ['platform', 'tenant'],
    example: 'tenant',
  })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({
    description: 'Email address, mobile number, or username associated with the account.',
    example: 'owner@example.com',
    maxLength: 160,
    minLength: 1,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiPropertyOptional({
    description: 'Tenant slug. Required when context is tenant.',
    example: 'acme-cleaning',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;
}

export class AuthResetPasswordDto {
  @ApiProperty({
    description: 'Account scope in which the reset was requested.',
    enum: ['platform', 'tenant'],
    example: 'tenant',
  })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({
    description: 'Email address, mobile number, or username associated with the account.',
    example: 'owner@example.com',
    maxLength: 160,
    minLength: 1,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiPropertyOptional({
    description: 'Tenant slug. Required when context is tenant.',
    example: 'acme-cleaning',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;

  @ApiProperty({
    description: 'Six-digit one-time password delivered for the reset request.',
    example: '482913',
    pattern: '^\\d{6}$',
  })
  @Matches(/^\d{6}$/)
  otp!: string;

  @ApiProperty({
    description:
      'Replacement password. It must contain uppercase, lowercase, numeric, and special characters.',
    example: 'NewSecurePassword1!',
    format: 'password',
    maxLength: 256,
    minLength: 8,
    pattern: '^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[^A-Za-z0-9]).+$',
  })
  @IsString()
  @MinLength(8)
  @MaxLength(256)
  newPassword!: string;
}

export class AuthChangePasswordDto {
  @ApiProperty({
    description: 'Current account password.',
    example: 'CurrentPassword1!',
    format: 'password',
    minLength: 1,
  })
  @IsString()
  @IsNotEmpty()
  currentPassword!: string;

  @ApiProperty({
    description:
      'Replacement password. It must contain uppercase, lowercase, numeric, and special characters.',
    example: 'NewSecurePassword1!',
    format: 'password',
    maxLength: 256,
    minLength: 8,
    pattern: '^(?=.*[A-Z])(?=.*[a-z])(?=.*\\d)(?=.*[^A-Za-z0-9]).+$',
  })
  @IsString()
  @MinLength(8)
  @MaxLength(256)
  newPassword!: string;
}
