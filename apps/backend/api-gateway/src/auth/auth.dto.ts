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
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(256)
  password!: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  branchCode?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceId?: string;

  @IsOptional()
  @IsString()
  @MaxLength(128)
  deviceName?: string;
}

export class AuthRefreshDto {
  @IsString()
  @IsNotEmpty()
  refreshToken!: string;
}

export class AuthForgotPasswordDto {
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;
}

export class AuthResetPasswordDto {
  @IsEnum(['platform', 'tenant'])
  context!: AuthLoginContext;

  @IsString()
  @IsNotEmpty()
  @MaxLength(160)
  identifier!: string;

  @IsOptional()
  @IsString()
  @MaxLength(64)
  tenantSlug?: string;

  @Matches(/^\d{6}$/)
  otp!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(256)
  newPassword!: string;
}

export class AuthChangePasswordDto {
  @IsString()
  @IsNotEmpty()
  currentPassword!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(256)
  newPassword!: string;
}
