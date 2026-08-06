import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AuthContractVersionDto {
  @ApiProperty({ description: 'Major contract version.', example: 1, minimum: 1 })
  readonly major!: number;

  @ApiProperty({ description: 'Minor contract version.', example: 0, minimum: 0 })
  readonly minor!: number;
}

export class AuthUserSummaryDto {
  @ApiProperty({ description: 'Unique user identifier.', example: 'user-1001' })
  readonly userId!: string;

  @ApiProperty({ description: 'User display name.', example: 'Aarav Sharma' })
  readonly displayName!: string;

  @ApiProperty({
    description: 'User email address.',
    example: 'owner@example.com',
    format: 'email',
  })
  readonly email!: string;

  @ApiPropertyOptional({ description: 'User mobile number.', example: '+919876543210' })
  readonly mobileNumber?: string;

  @ApiProperty({ description: 'Assigned role code.', example: 'TENANT_ADMIN' })
  readonly roleCode!: string;
}

export class AuthTenantSummaryDto {
  @ApiProperty({ description: 'Unique tenant identifier.', example: 'tenant-1001' })
  readonly tenantId!: string;

  @ApiProperty({ description: 'Tenant slug.', example: 'acme-cleaning' })
  readonly tenantSlug!: string;

  @ApiProperty({ description: 'Tenant display name.', example: 'Acme Cleaning Services' })
  readonly tenantName!: string;
}

export class AuthBranchSummaryDto {
  @ApiProperty({ description: 'Unique branch identifier.', example: 'branch-1001' })
  readonly branchId!: string;

  @ApiProperty({ description: 'Branch code.', example: 'BLR-01' })
  readonly branchCode!: string;

  @ApiProperty({ description: 'Branch display name.', example: 'Bengaluru Central' })
  readonly branchName!: string;
}

export class AuthSessionSummaryDto {
  @ApiProperty({ description: 'Unique session identifier.', example: 'session-1001' })
  readonly sessionId!: string;

  @ApiProperty({ description: 'Refresh-token family identifier.', example: 'family-1001' })
  readonly familyId!: string;

  @ApiPropertyOptional({
    description: 'Client-provided device identifier.',
    example: 'device-7f8a2c',
  })
  readonly deviceId?: string;

  @ApiPropertyOptional({ description: 'Human-readable device name.', example: 'Chrome on Windows' })
  readonly deviceName?: string;

  @ApiProperty({
    description: 'UTC timestamp at which the session expires.',
    example: '2026-08-10T10:30:00.000Z',
    format: 'date-time',
  })
  readonly expiresAtUtc!: string;
}

export class AuthLoginResponseDto {
  @ApiProperty({ description: 'JWT access token.', example: 'eyJhbGciOiJIUzI1NiJ9.access-token' })
  readonly accessToken!: string;

  @ApiProperty({
    description: 'Rotatable refresh token.',
    example: 'eyJhbGciOiJIUzI1NiJ9.refresh-token',
  })
  readonly refreshToken!: string;

  @ApiProperty({
    description: 'UTC timestamp at which the access token expires.',
    example: '2026-08-03T10:45:00.000Z',
    format: 'date-time',
  })
  readonly accessTokenExpiresAtUtc!: string;

  @ApiProperty({
    description: 'UTC timestamp at which the refresh token expires.',
    example: '2026-08-10T10:30:00.000Z',
    format: 'date-time',
  })
  readonly refreshTokenExpiresAtUtc!: string;

  @ApiProperty({ type: AuthContractVersionDto })
  readonly contractVersion!: AuthContractVersionDto;

  @ApiProperty({ type: AuthUserSummaryDto })
  readonly user!: AuthUserSummaryDto;

  @ApiPropertyOptional({ type: AuthTenantSummaryDto })
  readonly tenant?: AuthTenantSummaryDto;

  @ApiPropertyOptional({ type: AuthBranchSummaryDto })
  readonly branch?: AuthBranchSummaryDto;

  @ApiProperty({
    description: 'Permission codes granted to the session.',
    example: ['customers.read', 'jobs.manage'],
    isArray: true,
    type: String,
  })
  readonly permissions!: readonly string[];

  @ApiProperty({ type: AuthSessionSummaryDto })
  readonly session!: AuthSessionSummaryDto;
}

export class AuthRefreshResponseDto {
  @ApiProperty({
    description: 'New JWT access token.',
    example: 'eyJhbGciOiJIUzI1NiJ9.access-token',
  })
  readonly accessToken!: string;

  @ApiProperty({
    description: 'Rotated refresh token.',
    example: 'eyJhbGciOiJIUzI1NiJ9.refresh-token',
  })
  readonly refreshToken!: string;

  @ApiProperty({
    description: 'UTC timestamp at which the access token expires.',
    example: '2026-08-03T10:45:00.000Z',
    format: 'date-time',
  })
  readonly accessTokenExpiresAtUtc!: string;

  @ApiProperty({
    description: 'UTC timestamp at which the refresh token expires.',
    example: '2026-08-10T10:30:00.000Z',
    format: 'date-time',
  })
  readonly refreshTokenExpiresAtUtc!: string;

  @ApiProperty({ type: AuthContractVersionDto })
  readonly contractVersion!: AuthContractVersionDto;

  @ApiProperty({ type: AuthSessionSummaryDto })
  readonly session!: AuthSessionSummaryDto;
}

export class AuthAcknowledgementDto {
  @ApiProperty({
    description: 'Indicates that the operation was accepted.',
    enum: [true],
    example: true,
  })
  readonly accepted!: true;

  @ApiProperty({ type: AuthContractVersionDto })
  readonly contractVersion!: AuthContractVersionDto;
}

export class AuthResetRequestAcknowledgementDto extends AuthAcknowledgementDto {
  @ApiProperty({
    description: 'Masked delivery destination or a neutral eligibility message.',
    example: 'o***r@example.com',
  })
  readonly deliveryHint!: string;
}

export class AuthResponseMetaDto {
  @ApiProperty({
    description: 'Correlation identifier for tracing the request.',
    example: 'c28f7fa2-2733-4a6d-a589-34dbef3c2249',
    format: 'uuid',
  })
  readonly correlationId!: string;
}

export class AuthLoginResponseEnvelopeDto {
  @ApiProperty({ type: AuthLoginResponseDto })
  readonly data!: AuthLoginResponseDto;

  @ApiProperty({ type: AuthResponseMetaDto })
  readonly meta!: AuthResponseMetaDto;
}

export class AuthRefreshResponseEnvelopeDto {
  @ApiProperty({ type: AuthRefreshResponseDto })
  readonly data!: AuthRefreshResponseDto;

  @ApiProperty({ type: AuthResponseMetaDto })
  readonly meta!: AuthResponseMetaDto;
}

export class AuthAcknowledgementEnvelopeDto {
  @ApiProperty({ type: AuthAcknowledgementDto })
  readonly data!: AuthAcknowledgementDto;

  @ApiProperty({ type: AuthResponseMetaDto })
  readonly meta!: AuthResponseMetaDto;
}

export class AuthResetRequestAcknowledgementEnvelopeDto {
  @ApiProperty({ type: AuthResetRequestAcknowledgementDto })
  readonly data!: AuthResetRequestAcknowledgementDto;

  @ApiProperty({ type: AuthResponseMetaDto })
  readonly meta!: AuthResponseMetaDto;
}

export class AuthFieldErrorDto {
  @ApiProperty({ description: 'Request field associated with the error.', example: 'newPassword' })
  readonly field!: string;

  @ApiProperty({
    description: 'Machine-readable field error code.',
    example: 'auth.password_uppercase',
  })
  readonly code!: string;
}

export class AuthErrorDetailsDto {
  @ApiProperty({ description: 'Machine-readable error code.', example: 'auth.login_denied' })
  readonly code!: string;

  @ApiProperty({
    description: 'Broad error category.',
    enum: [
      'validation',
      'unauthenticated',
      'forbidden',
      'not_found',
      'conflict',
      'rate_limit',
      'dependency_unavailable',
      'timeout',
      'internal',
    ],
    example: 'unauthenticated',
  })
  readonly category!: string;

  @ApiProperty({
    description: 'Localization key for the public error message.',
    example: 'errors.auth.login_denied',
  })
  readonly messageKey!: string;

  @ApiPropertyOptional({ isArray: true, type: AuthFieldErrorDto })
  readonly fields?: readonly AuthFieldErrorDto[];

  @ApiProperty({ description: 'Whether retrying the request may succeed.', example: false })
  readonly retryable!: boolean;

  @ApiProperty({
    description: 'Correlation identifier for tracing the failed request.',
    example: 'c28f7fa2-2733-4a6d-a589-34dbef3c2249',
    format: 'uuid',
  })
  readonly correlationId!: string;
}

export class AuthErrorEnvelopeDto {
  @ApiProperty({ type: AuthErrorDetailsDto })
  readonly error!: AuthErrorDetailsDto;
}
