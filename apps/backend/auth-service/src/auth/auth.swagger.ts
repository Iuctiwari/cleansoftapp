import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

class ContractVersionDto {
  @ApiProperty({ example: 1 })
  major!: number;

  @ApiProperty({ example: 0 })
  minor!: number;
}

class AuthUserSummaryDto {
  @ApiProperty({ example: 'platform-admin-1' })
  userId!: string;

  @ApiProperty({ example: 'Platform Administrator' })
  displayName!: string;

  @ApiProperty({ example: 'platform.admin@nexoraa.local' })
  email!: string;

  @ApiPropertyOptional({ example: '9000000001' })
  mobileNumber?: string;

  @ApiProperty({ example: 'platform_admin' })
  roleCode!: string;
}

class AuthTenantSummaryDto {
  @ApiProperty({ example: 'tenant-alpha' })
  tenantId!: string;

  @ApiProperty({ example: 'alpha' })
  tenantSlug!: string;

  @ApiProperty({ example: 'Alpha CleanSoft' })
  tenantName!: string;
}

class AuthBranchSummaryDto {
  @ApiProperty({ example: 'branch-alpha-main' })
  branchId!: string;

  @ApiProperty({ example: 'main' })
  branchCode!: string;

  @ApiProperty({ example: 'Main Branch' })
  branchName!: string;
}

class AuthSessionSummaryDto {
  @ApiProperty({ example: 'session-9d6cb4d6' })
  sessionId!: string;

  @ApiProperty({ example: 'family-a6e4cb75' })
  familyId!: string;

  @ApiPropertyOptional({ example: 'device-android-01' })
  deviceId?: string;

  @ApiPropertyOptional({ example: 'Pixel 8 Pro' })
  deviceName?: string;

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  expiresAtUtc!: string;
}

export class AuthLoginResponseDto {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access' })
  accessToken!: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh' })
  refreshToken!: string;

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  accessTokenExpiresAtUtc!: string;

  @ApiProperty({ example: '2026-08-10T10:15:30.000Z' })
  refreshTokenExpiresAtUtc!: string;

  @ApiProperty({ type: ContractVersionDto })
  contractVersion!: ContractVersionDto;

  @ApiProperty({ type: AuthUserSummaryDto })
  user!: AuthUserSummaryDto;

  @ApiPropertyOptional({ type: AuthTenantSummaryDto })
  tenant?: AuthTenantSummaryDto;

  @ApiPropertyOptional({ type: AuthBranchSummaryDto })
  branch?: AuthBranchSummaryDto;

  @ApiProperty({
    type: [String],
    example: ['platform:read', 'platform:write', 'audit:read'],
  })
  permissions!: string[];

  @ApiProperty({ type: AuthSessionSummaryDto })
  session!: AuthSessionSummaryDto;
}

export class AuthRefreshResponseDto {
  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access' })
  accessToken!: string;

  @ApiProperty({ example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh' })
  refreshToken!: string;

  @ApiProperty({ example: '2026-08-03T10:15:30.000Z' })
  accessTokenExpiresAtUtc!: string;

  @ApiProperty({ example: '2026-08-10T10:15:30.000Z' })
  refreshTokenExpiresAtUtc!: string;

  @ApiProperty({ type: ContractVersionDto })
  contractVersion!: ContractVersionDto;

  @ApiProperty({ type: AuthSessionSummaryDto })
  session!: AuthSessionSummaryDto;
}

export class AuthAcknowledgementDto {
  @ApiProperty({ example: true })
  accepted!: true;

  @ApiProperty({ type: ContractVersionDto })
  contractVersion!: ContractVersionDto;
}

export class AuthResetRequestAcknowledgementDto extends AuthAcknowledgementDto {
  @ApiProperty({
    example: 'p***m.admin@nexoraa.local',
    description: 'Masked delivery hint or generic eligibility message.',
  })
  deliveryHint!: string;
}
