import {
  Body,
  ConflictException,
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
import {
  IsArray,
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

import { hashPassword } from '../auth/auth.crypto';
import { MongoAuthRepository } from '../auth/auth.mongo.repository';
import { STAFF_ROLES_PERMISSIONS } from '../auth/auth.types';
import { EmailService } from '../email/email.service';

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
  @IsArray() @IsString({ each: true }) branchIds!: string[];
  /** Email the staff member an invitation to set their password (needs `email`). */
  @IsOptional() @IsBoolean() sendInvite?: boolean;
}

class UpdateStaffStatusDto {
  @IsEnum(['active', 'disabled']) status!: 'active' | 'disabled';
}

class UpdateStaffAccessDto {
  @IsString() @IsNotEmpty() roleCode!: string;
  @IsArray() @IsString({ each: true }) branchIds!: string[];
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
    private readonly emailService: EmailService,
  ) {}

  @Post('provision')
  async provision(
    @Headers('x-internal-secret') secret: string,
    @Body() dto: ProvisionStaffDto,
  ): Promise<{ userId: string; inviteSent: boolean }> {
    this.assertInternalSecret(secret);

    if (await this.authRepository.isOwnerLogin(dto.loginId)) {
      throw new ConflictException(
        'This email is already used to sign in as a shop owner. Use a different email or login ID for this staff member.',
      );
    }

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
      branchIds: Object.freeze([...dto.branchIds]),
      status: 'active',
      accessVersion: 1,
      createdAtUtc: new Date().toISOString(),
    });

    // The account exists either way; a failed invitation email must not undo it
    // (the owner can still share the login ID and ask them to use Forgot password).
    let inviteSent = false;
    if (dto.sendInvite && dto.email) {
      const result = await this.emailService.sendStaffInvitation({
        email: dto.email,
        staffName: dto.displayName,
        businessName: dto.tenantName,
        loginId: dto.loginId.trim().toLowerCase(),
        role: dto.roleCode,
      });
      inviteSent = result.success;
    }

    return { userId: dto.userId, inviteSent };
  }

  @Patch(':userId/status')
  async updateStatus(
    @Headers('x-internal-secret') secret: string,
    @Param('userId') userId: string,
    @Body() dto: UpdateStaffStatusDto,
  ): Promise<void> {
    this.assertInternalSecret(secret);
    await this.authRepository.updateStaffIdentityStatus(userId, dto.status);
    await this.authRepository.revokeSessionsByUser(
      userId,
      'staff_status_changed',
      new Date().toISOString(),
    );
  }

  @Patch(':userId/access')
  async updateAccess(
    @Headers('x-internal-secret') secret: string,
    @Param('userId') userId: string,
    @Body() dto: UpdateStaffAccessDto,
  ): Promise<void> {
    this.assertInternalSecret(secret);
    const permissions = STAFF_ROLES_PERMISSIONS[dto.roleCode] ?? [];
    await this.authRepository.updateStaffIdentityAccess(
      userId,
      dto.roleCode,
      permissions,
      dto.branchIds,
    );
    await this.authRepository.revokeSessionsByUser(
      userId,
      'staff_access_changed',
      new Date().toISOString(),
    );
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
