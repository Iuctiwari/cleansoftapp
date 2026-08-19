import {
  Body,
  Controller,
  Delete,
  Headers,
  Param,
  Patch,
  Post,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiExcludeController } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

import { hashPassword } from '../auth/auth.crypto';
import { MongoAuthRepository } from '../auth/auth.mongo.repository';
import { STAFF_ROLES_PERMISSIONS } from '../auth/auth.types';

class ProvisionStaffDto {
  @IsString() @IsNotEmpty() userId!: string;
  @IsString() @IsNotEmpty() tenantId!: string;
  @IsString() @IsNotEmpty() tenantSlug!: string;
  @IsString() @IsNotEmpty() tenantName!: string;
  @IsString() @IsNotEmpty() @MaxLength(160) loginId!: string;
  @IsString() @IsNotEmpty() @MaxLength(120) displayName!: string;
  @IsOptional() @IsString() @MaxLength(160) email?: string;
  @IsString() @IsNotEmpty() @MaxLength(256) password!: string;
  @IsString() @IsNotEmpty() roleCode!: string;
}

class UpdateStaffStatusDto {
  @IsEnum(['active', 'disabled']) status!: 'active' | 'disabled';
}

/**
 * Internal-only controller for provisioning staff auth credentials.
 * Called by user-service when an owner registers a new employee.
 * Protected by a shared internal secret header (x-internal-secret).
 */
@ApiExcludeController()
@Controller({ path: 'internal/staff', version: '1' })
export class StaffProvisioningController {
  constructor(
    private readonly authRepository: MongoAuthRepository,
    private readonly configService: ConfigService,
  ) {}

  @Post('provision')
  async provision(
    @Headers('x-internal-secret') secret: string,
    @Body() dto: ProvisionStaffDto,
  ): Promise<{ userId: string }> {
    this.assertInternalSecret(secret);

    const permissions = STAFF_ROLES_PERMISSIONS[dto.roleCode] ?? [];
    await this.authRepository.createStaffIdentity({
      userId: dto.userId,
      tenantId: dto.tenantId,
      tenantSlug: dto.tenantSlug,
      tenantName: dto.tenantName,
      loginId: dto.loginId.trim().toLowerCase(),
      displayName: dto.displayName,
      email: dto.email,
      passwordHash: hashPassword(dto.password),
      roleCode: dto.roleCode,
      permissions,
      status: 'active',
      accessVersion: 1,
      createdAtUtc: new Date().toISOString(),
    });

    return { userId: dto.userId };
  }

  @Patch(':userId/status')
  async updateStatus(
    @Headers('x-internal-secret') secret: string,
    @Param('userId') userId: string,
    @Body() dto: UpdateStaffStatusDto,
  ): Promise<void> {
    this.assertInternalSecret(secret);
    await this.authRepository.updateStaffIdentityStatus(userId, dto.status);
  }

  @Delete(':userId')
  async removeStaff(
    @Headers('x-internal-secret') secret: string,
    @Param('userId') userId: string,
  ): Promise<void> {
    this.assertInternalSecret(secret);
    await this.authRepository.deleteStaffIdentity(userId);
  }

  private assertInternalSecret(provided: string): void {
    const expected = this.configService.get<string>('INTERNAL_SERVICE_SECRET');
    if (!expected || provided !== expected) {
      throw new UnauthorizedException('Invalid internal secret');
    }
  }
}
