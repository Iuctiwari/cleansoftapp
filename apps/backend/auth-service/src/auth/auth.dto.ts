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
    description: 'Login context — use "tenant" for business users, "platform" for operators',
    enum: ['platform', 'tenant'],
    example: 'tenant',
  })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({
    description: 'Email address or phone number of the account',
    example: 'owner@mybusiness.com',
    maxLength: 160,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiProperty({
    description: 'Account password',
    example: 'MyStr0ng!Pass',
    maxLength: 256,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  password!: string;

  @ApiPropertyOptional({
    description: 'Tenant slug — required when context is "tenant"',
    example: 'ahmed-laundry',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;

  @ApiPropertyOptional({
    description: 'Branch code for multi-branch tenants',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  branchCode?: string;

  @ApiPropertyOptional({
    description: 'Unique device identifier for session tracking',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;

  @ApiPropertyOptional({
    description: 'Human-readable device name',
    example: 'iPhone 15 Pro',
    maxLength: 128,
  })
  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceName?: string;
}

export class AuthRefreshDto {
  @ApiProperty({
    description: 'Opaque refresh token issued during login',
  })
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}

export class AuthForgotPasswordDto {
  @ApiProperty({
    description: 'Login context',
    enum: ['platform', 'tenant'],
    example: 'tenant',
  })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({
    description: 'Email address or phone number of the account',
    example: 'owner@mybusiness.com',
    maxLength: 160,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiPropertyOptional({
    description: 'Tenant slug — required when context is "tenant"',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;
}

export class AuthResetPasswordDto {
  @ApiProperty({
    description: 'Login context',
    enum: ['platform', 'tenant'],
    example: 'tenant',
  })
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @ApiProperty({
    description: 'Email address or phone number of the account',
    example: 'owner@mybusiness.com',
    maxLength: 160,
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @ApiPropertyOptional({
    description: 'Tenant slug — required when context is "tenant"',
    maxLength: 64,
  })
  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;

  @ApiProperty({
    description: '6-digit OTP sent to the account email/phone',
    pattern: '^\\d{6}$',
    example: '123456',
  })
  @Matches(/^\d{6}$/)
  otp!: string;

  @ApiProperty({
    description: 'New password (min 8 chars, requires upper/lowercase, digit, special char)',
    minLength: 8,
    maxLength: 256,
  })
  @IsString()
  @MinLength(8)
  @MaxLength(256)
  newPassword!: string;
}

export class AuthChangePasswordDto {
  @ApiProperty({
    description: 'Current account password',
  })
  @IsString()
  @IsNotEmpty()
  currentPassword!: string;

  @ApiProperty({
    description: 'New password (min 8 chars, requires upper/lowercase, digit, special char)',
    minLength: 8,
    maxLength: 256,
  })
  @IsString()
  @MinLength(8)
  @MaxLength(256)
  newPassword!: string;
}
