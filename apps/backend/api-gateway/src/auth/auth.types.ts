import type { RequestWithPlatformContext } from '../platform/platform.request';
import type { ContractVersion, TrustedContext } from '../platform/platform.types';

export type AuthLoginContext = 'platform' | 'tenant';
export type AuthTokenKind = 'access' | 'refresh';
export type AuthIdentityStatus = 'active' | 'disabled';
export type AuthResetDeliveryChannel = 'email' | 'sms';

export interface AuthBranchAssignment {
  readonly branchId: string;
  readonly branchCode: string;
  readonly branchName: string;
}

export interface AuthIdentityRecord {
  readonly userId: string;
  readonly kind: AuthLoginContext;
  readonly email: string;
  readonly mobileNumber?: string;
  readonly displayName: string;
  readonly passwordHash: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
  readonly status: AuthIdentityStatus;
  readonly accessVersion: number;
  readonly tenantId?: string;
  readonly tenantSlug?: string;
  readonly tenantName?: string;
  readonly tenantStatus?: 'active' | 'disabled';
  readonly branches: readonly AuthBranchAssignment[];
  readonly defaultBranchId?: string;
  readonly passwordChangedAtUtc: string;
}

export interface AuthLoginTracker {
  readonly trackerKey: string;
  readonly failedAttempts: number;
  readonly lockedUntilUtc?: string;
  readonly updatedAtUtc: string;
}

export interface AuthSessionRecord {
  readonly sessionId: string;
  readonly familyId: string;
  readonly userId: string;
  readonly kind: AuthLoginContext;
  readonly roleCode: string;
  readonly permissions: readonly string[];
  readonly accessVersion: number;
  readonly tenantId?: string;
  readonly tenantSlug?: string;
  readonly tenantName?: string;
  readonly branchId?: string;
  readonly branchCode?: string;
  readonly branchName?: string;
  readonly refreshTokenHash: string;
  readonly expiresAtUtc: string;
  readonly createdAtUtc: string;
  readonly lastActivityAtUtc: string;
  readonly revokedAtUtc?: string;
  readonly revokedReason?: string;
  readonly reuseDetectedAtUtc?: string;
  readonly deviceId?: string;
  readonly deviceName?: string;
  readonly ipAddress?: string;
  readonly userAgent?: string;
}

export interface PasswordResetRecord {
  readonly resetId: string;
  readonly userId: string;
  readonly kind: AuthLoginContext;
  readonly tenantId?: string;
  readonly tenantSlug?: string;
  readonly otpHash: string;
  readonly expiresAtUtc: string;
  readonly attempts: number;
  readonly consumed: boolean;
  readonly createdAtUtc: string;
  readonly deliveryChannel: AuthResetDeliveryChannel;
  readonly destinationMasked: string;
}

export interface AuthNotificationIntent {
  readonly notificationId: string;
  readonly channel: AuthResetDeliveryChannel;
  readonly destinationMasked: string;
  readonly templateCode: string;
  readonly payload: Record<string, string>;
  readonly createdAtUtc: string;
}

export interface AuthAuditReference {
  readonly sourceObligation: string;
  readonly idempotencyKey: string;
}

export interface AuthAccessTokenClaims {
  readonly tokenKind: 'access';
  readonly sessionId: string;
  readonly userId: string;
  readonly kind: AuthLoginContext;
  readonly roleCode: string;
  readonly permissions: readonly string[];
  readonly accessVersion: number;
  readonly tenantId?: string;
  readonly branchId?: string;
}

export interface AuthRefreshTokenClaims {
  readonly tokenKind: 'refresh';
  readonly sessionId: string;
  readonly familyId: string;
  readonly userId: string;
  readonly kind: AuthLoginContext;
}

export interface SignedTokenEnvelope<TClaims> {
  readonly issuer: string;
  readonly audience: string;
  readonly subject: string;
  readonly tokenKind: AuthTokenKind;
  readonly issuedAt: number;
  readonly expiresAt: number;
  readonly claims: TClaims;
}

export interface AuthenticatedPrincipal {
  readonly context: TrustedContext;
  readonly session: AuthSessionRecord;
}

export interface AuthTokens {
  readonly accessToken: string;
  readonly refreshToken: string;
  readonly accessTokenExpiresAtUtc: string;
  readonly refreshTokenExpiresAtUtc: string;
}

export interface AuthUserSummary {
  readonly userId: string;
  readonly displayName: string;
  readonly email: string;
  readonly mobileNumber?: string;
  readonly roleCode: string;
}

export interface AuthTenantSummary {
  readonly tenantId: string;
  readonly tenantSlug: string;
  readonly tenantName: string;
}

export interface AuthBranchSummary {
  readonly branchId: string;
  readonly branchCode: string;
  readonly branchName: string;
}

export interface AuthSessionSummary {
  readonly sessionId: string;
  readonly familyId: string;
  readonly deviceId?: string;
  readonly deviceName?: string;
  readonly expiresAtUtc: string;
}

export interface AuthLoginResponse extends AuthTokens {
  readonly contractVersion: ContractVersion;
  readonly user: AuthUserSummary;
  readonly tenant?: AuthTenantSummary;
  readonly branch?: AuthBranchSummary;
  readonly permissions: readonly string[];
  readonly session: AuthSessionSummary;
}

export interface AuthRefreshResponse extends AuthTokens {
  readonly contractVersion: ContractVersion;
  readonly session: AuthSessionSummary;
}

export interface AuthAcknowledgement {
  readonly accepted: true;
  readonly contractVersion: ContractVersion;
}

export interface AuthResetRequestAcknowledgement extends AuthAcknowledgement {
  readonly deliveryHint: string;
}

export interface AuthRequestMetadata {
  readonly correlationId: string;
  readonly causationId: string;
  readonly requestId: string;
  readonly ipAddress?: string;
  readonly userAgent?: string;
}

export interface AuthLoginInput {
  readonly context: AuthLoginContext;
  readonly identifier: string;
  readonly password: string;
  readonly tenantSlug?: string;
  readonly branchCode?: string;
  readonly deviceId?: string;
  readonly deviceName?: string;
  readonly metadata: AuthRequestMetadata;
}

export interface AuthRefreshInput {
  readonly refreshToken: string;
  readonly metadata: AuthRequestMetadata;
}

export interface AuthLogoutInput {
  readonly context: TrustedContext;
  readonly metadata: AuthRequestMetadata;
}

export interface AuthLogoutAllInput extends AuthLogoutInput {
  readonly exceptSessionId?: string;
}

export interface AuthForgotPasswordInput {
  readonly context: AuthLoginContext;
  readonly identifier: string;
  readonly tenantSlug?: string;
  readonly metadata: AuthRequestMetadata;
}

export interface AuthResetPasswordInput {
  readonly context: AuthLoginContext;
  readonly identifier: string;
  readonly tenantSlug?: string;
  readonly otp: string;
  readonly newPassword: string;
  readonly metadata: AuthRequestMetadata;
}

export interface AuthChangePasswordInput {
  readonly context: TrustedContext;
  readonly currentPassword: string;
  readonly newPassword: string;
  readonly metadata: AuthRequestMetadata;
}

export interface AuthSeedAccount {
  readonly userId: string;
  readonly kind: AuthLoginContext;
  readonly email: string;
  readonly mobileNumber?: string;
  readonly displayName: string;
  readonly password: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
  readonly status?: AuthIdentityStatus;
  readonly accessVersion?: number;
  readonly tenantId?: string;
  readonly tenantSlug?: string;
  readonly tenantName?: string;
  readonly tenantStatus?: 'active' | 'disabled';
  readonly branches?: readonly AuthBranchAssignment[];
  readonly defaultBranchId?: string;
  readonly passwordChangedAtUtc?: string;
}

export interface AuthRepository {
  findIdentity(
    context: AuthLoginContext,
    identifier: string,
    tenantSlug?: string,
  ): Promise<AuthIdentityRecord | null>;
  findIdentityByUserId(userId: string): Promise<AuthIdentityRecord | null>;
  resetLoginTracker(trackerKey: string): Promise<void>;
  getLoginTracker(trackerKey: string): Promise<AuthLoginTracker | null>;
  saveLoginTracker(tracker: AuthLoginTracker): Promise<AuthLoginTracker>;
  replaceIdentity(identity: AuthIdentityRecord): Promise<AuthIdentityRecord>;
  createSession(session: AuthSessionRecord): Promise<AuthSessionRecord>;
  updateSession(session: AuthSessionRecord): Promise<AuthSessionRecord>;
  findSessionById(sessionId: string): Promise<AuthSessionRecord | null>;
  listActiveSessionsByUser(userId: string): Promise<readonly AuthSessionRecord[]>;
  revokeSessionsByFamily(
    familyId: string,
    reason: string,
    revokedAtUtc: string,
  ): Promise<readonly AuthSessionRecord[]>;
  revokeSessionsByUser(
    userId: string,
    reason: string,
    revokedAtUtc: string,
    exceptSessionId?: string,
  ): Promise<readonly AuthSessionRecord[]>;
  upsertPasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord>;
  findActivePasswordResetByUser(userId: string): Promise<PasswordResetRecord | null>;
  findActivePasswordResetByLocator(
    context: AuthLoginContext,
    identifier: string,
    tenantSlug?: string,
  ): Promise<PasswordResetRecord | null>;
  consumePasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord>;
  updatePasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord>;
  recordNotification(intent: AuthNotificationIntent): Promise<AuthNotificationIntent>;
}

export interface AccessTokenResolution {
  readonly principal: AuthenticatedPrincipal;
  readonly envelope: SignedTokenEnvelope<AuthAccessTokenClaims>;
}

export interface AuthContextRequest extends RequestWithPlatformContext {
  readonly method?: string;
  readonly url?: string;
  readonly ip?: string;
}

export const AUTH_REPOSITORY = Symbol('AUTH_REPOSITORY');
