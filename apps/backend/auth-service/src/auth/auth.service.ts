import { randomUUID } from 'node:crypto';

import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuditService } from '../audit/audit.service';
import { TrustedContextFactory } from '../platform/platform.context';
import { PlatformError } from '../platform/platform.errors';
import type { PlatformContext, TenantContext, TrustedContext } from '../platform/platform.types';
import {
  createAccessTokenId,
  createRefreshFamilyId,
  generateOtp,
  hashOpaqueSecret,
  hashPassword,
  maskDestination,
  signToken,
  verifyLegacyTenantPassword,
  verifyPassword,
  verifyToken,
} from './auth.crypto';
import { normalizeIdentifier } from './auth.normalization';
import {
  AUTH_REPOSITORY,
  type AccessTokenResolution,
  type AuthAccessTokenClaims,
  type AuthAcknowledgement,
  type AuthChangePasswordInput,
  type AuthenticatedBranchContext,
  type AuthForgotPasswordInput,
  type AuthIdentityRecord,
  type AuthLoginInput,
  type AuthLoginResponse,
  type AuthLogoutAllInput,
  type AuthLogoutInput,
  type AuthRefreshInput,
  type AuthRefreshResponse,
  type AuthRefreshTokenClaims,
  type AuthRepository,
  type AuthRequestMetadata,
  type AuthResetPasswordInput,
  type AuthResetRequestAcknowledgement,
  type AuthSessionRecord,
  type AuthTokens,
  type PasswordResetRecord,
  type SignedTokenEnvelope,
} from './auth.types';

interface AuthConfiguration {
  readonly issuer: string;
  readonly audience: string;
  readonly accessTokenSecret: string;
  readonly refreshTokenSecret: string;
  readonly accessTokenTtlSeconds: number;
  readonly refreshTokenTtlSeconds: number;
  readonly loginMaxAttempts: number;
  readonly lockoutSeconds: number;
  readonly otpTtlSeconds: number;
  readonly otpMaxAttempts: number;
  readonly maxActiveSessions: number;
  readonly allowMultiDevice: boolean;
}

// Keep the established audience so access and refresh tokens issued before consolidation remain valid.
const AUTH_TOKEN_AUDIENCE = 'api-gateway';

function addSeconds(date: Date, seconds: number): Date {
  return new Date(date.getTime() + seconds * 1000);
}

function parseBoolean(value: string | undefined, fallback: boolean): boolean {
  if (!value) {
    return fallback;
  }

  return value.trim().toLowerCase() === 'true';
}

function assertStrongPassword(password: string): void {
  const checks = [
    { field: 'newPassword', code: 'auth.password_min_length', ok: password.length >= 8 },
    { field: 'newPassword', code: 'auth.password_uppercase', ok: /[A-Z]/.test(password) },
    { field: 'newPassword', code: 'auth.password_lowercase', ok: /[a-z]/.test(password) },
    { field: 'newPassword', code: 'auth.password_number', ok: /\d/.test(password) },
    { field: 'newPassword', code: 'auth.password_special', ok: /[^A-Za-z0-9]/.test(password) },
  ];

  const failures = checks
    .filter((check) => !check.ok)
    .map((check) => ({ field: check.field, code: check.code }));
  if (failures.length > 0) {
    throw new PlatformError({
      code: 'auth.password_policy_failed',
      category: 'validation',
      messageKey: 'errors.auth.password_policy_failed',
      fields: failures,
    });
  }
}

function toAcknowledgement(): AuthAcknowledgement {
  return {
    accepted: true,
    contractVersion: { major: 1, minor: 0 },
  };
}

function toSessionSummary(session: AuthSessionRecord): AuthLoginResponse['session'] {
  return {
    sessionId: session.sessionId,
    familyId: session.familyId,
    deviceId: session.deviceId,
    deviceName: session.deviceName,
    expiresAtUtc: session.expiresAtUtc,
  };
}

@Injectable()
export class AuthService {
  private readonly configuration: AuthConfiguration;

  constructor(
    @Inject(AUTH_REPOSITORY) private readonly authRepository: AuthRepository,
    private readonly auditService: AuditService,
    private readonly configService: ConfigService,
    private readonly trustedContextFactory: TrustedContextFactory,
  ) {
    this.configuration = {
      issuer: this.configService.getOrThrow<string>('APP_NAME'),
      audience: AUTH_TOKEN_AUDIENCE,
      accessTokenSecret: this.configService.getOrThrow<string>('AUTH_ACCESS_TOKEN_SECRET'),
      refreshTokenSecret: this.configService.getOrThrow<string>('AUTH_REFRESH_TOKEN_SECRET'),
      accessTokenTtlSeconds: Number(
        this.configService.getOrThrow<string>('AUTH_ACCESS_TOKEN_TTL_SECONDS'),
      ),
      refreshTokenTtlSeconds: Number(
        this.configService.getOrThrow<string>('AUTH_REFRESH_TOKEN_TTL_SECONDS'),
      ),
      loginMaxAttempts: Number(this.configService.getOrThrow<string>('AUTH_LOGIN_MAX_ATTEMPTS')),
      lockoutSeconds: Number(this.configService.getOrThrow<string>('AUTH_LOCKOUT_SECONDS')),
      otpTtlSeconds: Number(this.configService.getOrThrow<string>('AUTH_OTP_TTL_SECONDS')),
      otpMaxAttempts: Number(this.configService.getOrThrow<string>('AUTH_OTP_MAX_ATTEMPTS')),
      maxActiveSessions: Number(this.configService.getOrThrow<string>('AUTH_MAX_ACTIVE_SESSIONS')),
      allowMultiDevice: parseBoolean(
        this.configService.getOrThrow<string>('AUTH_ALLOW_MULTI_DEVICE'),
        true,
      ),
    };
  }

  async login(input: AuthLoginInput): Promise<AuthLoginResponse> {
    const trackerKey = this.createTrackerKey(input.context, input.identifier, input.tenantSlug);
    await this.assertTrackerAllowsLogin(trackerKey);

    const identity = await this.authRepository.findIdentity(
      input.context,
      normalizeIdentifier(input.identifier),
    );

    const passwordMatchesScrypt =
      identity !== null && verifyPassword(input.password, identity.passwordHash);
    const passwordMatchesLegacy =
      identity !== null && verifyLegacyTenantPassword(input.password, identity.passwordHash);
    const passwordMatches = passwordMatchesScrypt || passwordMatchesLegacy;

    if (!identity || !this.isLoginAllowed(identity) || !passwordMatches) {
      await this.recordLoginFailure(trackerKey, input, identity);
      throw new PlatformError({
        code: 'auth.login_denied',
        category: 'unauthenticated',
        messageKey: 'errors.auth.login_denied',
      });
    }

    if (passwordMatchesLegacy) {
      await this.authRepository.replaceIdentity({
        ...identity,
        passwordHash: hashPassword(input.password),
      });
    }

    const branch = this.resolveBranch(identity, input.branchCode);
    await this.authRepository.resetLoginTracker(trackerKey);
    await this.enforceConcurrentSessionPolicy(identity.userId);

    const issuedAt = new Date();
    const sessionId = createAccessTokenId();
    const familyId = createRefreshFamilyId();
    const refreshPayload = {
      tokenKind: 'refresh' as const,
      sessionId,
      familyId,
      userId: identity.userId,
      kind: identity.kind,
    };

    const refresh = signToken('refresh', identity.userId, refreshPayload, {
      issuer: this.configuration.issuer,
      audience: this.configuration.audience,
      secret: this.configuration.refreshTokenSecret,
      expiresInSeconds: this.configuration.refreshTokenTtlSeconds,
      now: issuedAt,
    });

    const session: AuthSessionRecord = {
      sessionId,
      familyId,
      userId: identity.userId,
      kind: identity.kind,
      roleCode: identity.roleCode,
      permissions: Object.freeze([...identity.permissions]),
      accessVersion: identity.accessVersion,
      tenantId: identity.tenantId,
      tenantSlug: identity.tenantSlug,
      tenantName: identity.tenantName,
      branchId: branch?.branchId,
      branchCode: branch?.branchCode,
      branchName: branch?.branchName,
      refreshTokenHash: hashOpaqueSecret(refresh.token, this.configuration.refreshTokenSecret),
      expiresAtUtc: new Date(refresh.envelope.expiresAt * 1000).toISOString(),
      createdAtUtc: issuedAt.toISOString(),
      lastActivityAtUtc: issuedAt.toISOString(),
      deviceId: input.deviceId,
      deviceName: input.deviceName,
      ipAddress: input.metadata.ipAddress,
      userAgent: input.metadata.userAgent,
    };
    await this.authRepository.createSession(session);

    const principalContext = this.createTrustedContext(identity, session, input.metadata);
    const access = signToken('access', identity.userId, this.createAccessClaims(principalContext), {
      issuer: this.configuration.issuer,
      audience: this.configuration.audience,
      secret: this.configuration.accessTokenSecret,
      expiresInSeconds: this.configuration.accessTokenTtlSeconds,
      now: issuedAt,
    });

    await this.auditService.recordAudit({
      sourceObligation: `auth:login:${session.sessionId}`,
      idempotencyKey: `auth:login:${session.sessionId}`,
      module: 'auth',
      action: 'login_success',
      classification: 'security',
      actor: { actorId: identity.userId, actorType: 'user' },
      target: { targetId: session.sessionId, targetType: 'auth_session' },
      context: principalContext,
      newSummary: {
        fields: {
          sessionId: session.sessionId,
          deviceName: session.deviceName ?? null,
        },
      },
      retentionTags: [{ code: 'security', label: 'Security' }],
      contractVersion: { major: 1, minor: 0 },
    });

    return {
      ...this.createTokenResponse(
        access.token,
        access.envelope.expiresAt,
        refresh.token,
        refresh.envelope.expiresAt,
      ),
      contractVersion: { major: 1, minor: 0 },
      user: {
        userId: identity.userId,
        displayName: identity.displayName,
        email: identity.email,
        mobileNumber: identity.mobileNumber,
        roleCode: identity.roleCode,
      },
      tenant:
        identity.kind === 'tenant' &&
        identity.tenantId &&
        identity.tenantSlug &&
        identity.tenantName
          ? {
              tenantId: identity.tenantId,
              tenantSlug: identity.tenantSlug,
              tenantName: identity.tenantName,
            }
          : undefined,
      branch: branch
        ? {
            branchId: branch.branchId,
            branchCode: branch.branchCode,
            branchName: branch.branchName,
          }
        : undefined,
      permissions: identity.permissions,
      session: toSessionSummary(session),
    };
  }

  async refresh(input: AuthRefreshInput): Promise<AuthRefreshResponse> {
    const envelope = verifyToken<AuthRefreshTokenClaims>(
      input.refreshToken,
      this.configuration.refreshTokenSecret,
      'refresh',
    );
    this.assertTokenEnvelope(envelope);
    const session = await this.authRepository.findSessionById(envelope.claims.sessionId);
    if (!session) {
      throw new PlatformError({
        code: 'auth.session_expired',
        category: 'unauthenticated',
        messageKey: 'errors.auth.session_expired',
      });
    }

    if (session.revokedAtUtc) {
      throw new PlatformError({
        code: 'auth.session_revoked',
        category: 'unauthenticated',
        messageKey: 'errors.auth.session_revoked',
      });
    }

    const incomingHash = hashOpaqueSecret(
      input.refreshToken,
      this.configuration.refreshTokenSecret,
    );
    if (incomingHash !== session.refreshTokenHash) {
      const revokedAtUtc = new Date().toISOString();
      await this.authRepository.revokeSessionsByFamily(
        session.familyId,
        'refresh_token_reuse_detected',
        revokedAtUtc,
      );
      await this.recordSecurityEvent('refresh_token_reuse_detected', session, input.metadata);
      throw new PlatformError({
        code: 'auth.refresh_reuse_detected',
        category: 'unauthenticated',
        messageKey: 'errors.auth.refresh_reuse_detected',
      });
    }

    const issuedAt = new Date();
    const rotated = signToken(
      'refresh',
      session.userId,
      {
        tokenKind: 'refresh' as const,
        sessionId: session.sessionId,
        familyId: session.familyId,
        userId: session.userId,
        kind: session.kind,
      },
      {
        issuer: this.configuration.issuer,
        audience: this.configuration.audience,
        secret: this.configuration.refreshTokenSecret,
        expiresInSeconds: this.configuration.refreshTokenTtlSeconds,
        now: issuedAt,
      },
    );
    const updatedSession: AuthSessionRecord = {
      ...session,
      refreshTokenHash: hashOpaqueSecret(rotated.token, this.configuration.refreshTokenSecret),
      expiresAtUtc: new Date(rotated.envelope.expiresAt * 1000).toISOString(),
      lastActivityAtUtc: issuedAt.toISOString(),
      ipAddress: input.metadata.ipAddress ?? session.ipAddress,
      userAgent: input.metadata.userAgent ?? session.userAgent,
    };
    await this.authRepository.updateSession(updatedSession);

    const principalContext = this.createTrustedContextFromSession(updatedSession, input.metadata);
    const access = signToken('access', session.userId, this.createAccessClaims(principalContext), {
      issuer: this.configuration.issuer,
      audience: this.configuration.audience,
      secret: this.configuration.accessTokenSecret,
      expiresInSeconds: this.configuration.accessTokenTtlSeconds,
      now: issuedAt,
    });

    await this.auditService.recordAudit({
      sourceObligation: `auth:refresh:${updatedSession.sessionId}:${issuedAt.toISOString()}`,
      idempotencyKey: `auth:refresh:${updatedSession.sessionId}:${rotated.envelope.issuedAt}`,
      module: 'auth',
      action: 'refresh_success',
      classification: 'security',
      actor: { actorId: updatedSession.userId, actorType: 'user' },
      target: { targetId: updatedSession.sessionId, targetType: 'auth_session' },
      context: principalContext,
      retentionTags: [{ code: 'security', label: 'Security' }],
      contractVersion: { major: 1, minor: 0 },
    });

    return {
      ...this.createTokenResponse(
        access.token,
        access.envelope.expiresAt,
        rotated.token,
        rotated.envelope.expiresAt,
      ),
      contractVersion: { major: 1, minor: 0 },
      session: toSessionSummary(updatedSession),
    };
  }

  async logout(input: AuthLogoutInput): Promise<AuthAcknowledgement> {
    const sessionId = input.context.sessionId;
    if (!sessionId) {
      throw new PlatformError({
        code: 'auth.session_missing',
        category: 'validation',
        messageKey: 'errors.auth.session_missing',
      });
    }

    const session = await this.authRepository.findSessionById(sessionId);
    if (session && !session.revokedAtUtc) {
      await this.authRepository.updateSession({
        ...session,
        revokedAtUtc: new Date().toISOString(),
        revokedReason: 'logout',
      });
      await this.recordSecurityEvent('logout', session, input.metadata);
    }

    return toAcknowledgement();
  }

  async logoutAll(input: AuthLogoutAllInput): Promise<AuthAcknowledgement> {
    const revoked = await this.authRepository.revokeSessionsByUser(
      input.context.actorId,
      'logout_all',
      new Date().toISOString(),
      input.exceptSessionId,
    );
    for (const session of revoked) {
      await this.recordSecurityEvent('logout_all', session, input.metadata);
    }

    return toAcknowledgement();
  }

  async forgotPassword(input: AuthForgotPasswordInput): Promise<AuthResetRequestAcknowledgement> {
    this.assertTenantLoginInput(input.context, input.tenantSlug);
    const identity = await this.authRepository.findIdentity(
      input.context,
      normalizeIdentifier(input.identifier),
    );

    if (!identity || !this.isLoginAllowed(identity)) {
      return {
        ...toAcknowledgement(),
        deliveryHint: 'If the account is eligible, a reset code will be sent.',
      };
    }

    const now = new Date();
    const otp = generateOtp();
    const destination = identity.email || identity.mobileNumber || identity.userId;
    const record: PasswordResetRecord = {
      resetId: randomUUID(),
      userId: identity.userId,
      kind: identity.kind,
      tenantId: identity.tenantId,
      tenantSlug: identity.tenantSlug,
      otpHash: hashOpaqueSecret(otp, this.configuration.refreshTokenSecret),
      expiresAtUtc: addSeconds(now, this.configuration.otpTtlSeconds).toISOString(),
      attempts: 0,
      consumed: false,
      createdAtUtc: now.toISOString(),
      deliveryChannel: identity.mobileNumber ? 'sms' : 'email',
      destinationMasked: maskDestination(destination),
    };
    await this.authRepository.upsertPasswordReset(record);
    await this.authRepository.recordNotification({
      notificationId: randomUUID(),
      channel: record.deliveryChannel,
      destinationMasked: record.destinationMasked,
      templateCode: 'auth.reset_otp',
      payload: { otp, tenantSlug: identity.tenantSlug ?? 'platform' },
      createdAtUtc: now.toISOString(),
    });
    await this.recordSecurityEvent(
      'forgot_password_requested',
      this.toSyntheticSession(identity),
      input.metadata,
    );

    return {
      ...toAcknowledgement(),
      deliveryHint: record.destinationMasked,
    };
  }

  async resetPassword(input: AuthResetPasswordInput): Promise<AuthAcknowledgement> {
    this.assertTenantLoginInput(input.context, input.tenantSlug);
    assertStrongPassword(input.newPassword);

    const identity = await this.authRepository.findIdentity(
      input.context,
      normalizeIdentifier(input.identifier),
    );
    const reset = await this.authRepository.findActivePasswordResetByLocator(
      input.context,
      normalizeIdentifier(input.identifier),
      input.tenantSlug,
    );

    if (!identity || !reset || reset.consumed || reset.expiresAtUtc <= new Date().toISOString()) {
      throw new PlatformError({
        code: 'auth.reset_invalid',
        category: 'validation',
        messageKey: 'errors.auth.reset_invalid',
      });
    }

    if (reset.attempts >= this.configuration.otpMaxAttempts) {
      throw new PlatformError({
        code: 'auth.reset_attempts_exceeded',
        category: 'rate_limit',
        messageKey: 'errors.auth.reset_attempts_exceeded',
      });
    }

    const incomingHash = hashOpaqueSecret(input.otp, this.configuration.refreshTokenSecret);
    if (incomingHash !== reset.otpHash) {
      await this.authRepository.updatePasswordReset({
        ...reset,
        attempts: reset.attempts + 1,
      });
      throw new PlatformError({
        code: 'auth.reset_invalid',
        category: 'validation',
        messageKey: 'errors.auth.reset_invalid',
      });
    }

    await this.authRepository.consumePasswordReset({
      ...reset,
      attempts: reset.attempts + 1,
    });
    await this.authRepository.replaceIdentity({
      ...identity,
      passwordHash: hashPassword(input.newPassword),
      accessVersion: identity.accessVersion + 1,
      passwordChangedAtUtc: new Date().toISOString(),
    });
    await this.authRepository.revokeSessionsByUser(
      identity.userId,
      'password_reset',
      new Date().toISOString(),
    );
    await this.recordSecurityEvent(
      'password_reset',
      this.toSyntheticSession(identity),
      input.metadata,
    );

    return toAcknowledgement();
  }

  async changePassword(input: AuthChangePasswordInput): Promise<AuthAcknowledgement> {
    assertStrongPassword(input.newPassword);
    const identity = await this.loadIdentityForContext(input.context);
    if (!verifyPassword(input.currentPassword, identity.passwordHash)) {
      throw new PlatformError({
        code: 'auth.current_password_invalid',
        category: 'validation',
        messageKey: 'errors.auth.current_password_invalid',
      });
    }

    await this.authRepository.replaceIdentity({
      ...identity,
      passwordHash: hashPassword(input.newPassword),
      accessVersion: identity.accessVersion + 1,
      passwordChangedAtUtc: new Date().toISOString(),
    });
    await this.authRepository.revokeSessionsByUser(
      identity.userId,
      'password_changed',
      new Date().toISOString(),
      input.context.sessionId,
    );
    if (input.context.sessionId) {
      const session = await this.authRepository.findSessionById(input.context.sessionId);
      if (session) {
        await this.authRepository.updateSession({
          ...session,
          accessVersion: identity.accessVersion + 1,
        });
      }
    }
    await this.recordSecurityEvent(
      'password_changed',
      this.toSyntheticSession(identity),
      input.metadata,
    );

    return toAcknowledgement();
  }

  async authenticateAccessToken(
    token: string,
    metadata: AuthRequestMetadata,
  ): Promise<AccessTokenResolution> {
    const envelope = verifyToken<AuthAccessTokenClaims>(
      token,
      this.configuration.accessTokenSecret,
      'access',
    );
    this.assertTokenEnvelope(envelope);
    const session = await this.authRepository.findSessionById(envelope.claims.sessionId);
    if (!session || session.revokedAtUtc || session.expiresAtUtc <= new Date().toISOString()) {
      throw new PlatformError({
        code: 'auth.session_expired',
        category: 'unauthenticated',
        messageKey: 'errors.auth.session_expired',
      });
    }

    const context = this.createTrustedContextFromSession(session, metadata);
    return {
      principal: {
        context,
        session,
      },
      envelope,
    };
  }

  async authorizeBranchContext(
    context: TrustedContext,
    requestedBranchId?: string,
  ): Promise<AuthenticatedBranchContext> {
    if (context.kind !== 'tenant') {
      throw new PlatformError({
        code: 'auth.tenant_context_required',
        category: 'forbidden',
        messageKey: 'errors.auth.tenant_context_required',
      });
    }

    const branchId = requestedBranchId?.trim() || context.branchId;
    if (!branchId) {
      throw new PlatformError({
        code: 'auth.branch_unavailable',
        category: 'forbidden',
        messageKey: 'errors.auth.branch_unavailable',
      });
    }

    const identity = await this.authRepository.findIdentityByUserId(context.actorId);
    const assigned = identity?.branches.some((branch) => branch.branchId === branchId) ?? false;
    if (!identity || identity.tenantId !== context.tenantId || !assigned) {
      throw new PlatformError({
        code: 'auth.branch_unavailable',
        category: 'forbidden',
        messageKey: 'errors.auth.branch_unavailable',
      });
    }

    return {
      actorId: context.actorId,
      kind: 'tenant',
      tenantId: context.tenantId,
      branchId,
    };
  }

  private assertTenantLoginInput(context: 'platform' | 'tenant', tenantSlug?: string): void {
    if (context === 'tenant' && (!tenantSlug || tenantSlug.trim().length === 0)) {
      throw new PlatformError({
        code: 'auth.tenant_slug_required',
        category: 'validation',
        messageKey: 'errors.auth.tenant_slug_required',
        fields: [{ field: 'tenantSlug', code: 'auth.tenant_slug_required' }],
      });
    }
  }

  private async assertTrackerAllowsLogin(trackerKey: string): Promise<void> {
    const tracker = await this.authRepository.getLoginTracker(trackerKey);
    if (tracker?.lockedUntilUtc && tracker.lockedUntilUtc > new Date().toISOString()) {
      throw new PlatformError({
        code: 'auth.login_temporarily_blocked',
        category: 'rate_limit',
        messageKey: 'errors.auth.login_temporarily_blocked',
      });
    }
  }

  private async recordLoginFailure(
    trackerKey: string,
    input: AuthLoginInput,
    identity: AuthIdentityRecord | null,
  ): Promise<void> {
    const tracker = await this.authRepository.getLoginTracker(trackerKey);
    const failedAttempts = (tracker?.failedAttempts ?? 0) + 1;
    const now = new Date();
    await this.authRepository.saveLoginTracker({
      trackerKey,
      failedAttempts,
      lockedUntilUtc:
        failedAttempts >= this.configuration.loginMaxAttempts
          ? addSeconds(now, this.configuration.lockoutSeconds).toISOString()
          : undefined,
      updatedAtUtc: now.toISOString(),
    });

    await this.auditService.recordAudit({
      sourceObligation: `auth:login_failure:${trackerKey}:${failedAttempts}`,
      idempotencyKey: `auth:login_failure:${trackerKey}:${failedAttempts}`,
      module: 'auth',
      action:
        failedAttempts >= this.configuration.loginMaxAttempts ? 'login_locked' : 'login_failed',
      classification: 'security',
      actor: { actorId: identity?.userId ?? 'anonymous', actorType: 'user' },
      target: { targetId: trackerKey, targetType: 'auth_login_tracker' },
      context: this.createServiceContext(input.metadata),
      newSummary: {
        fields: {
          context: input.context,
          tenantSlug: input.tenantSlug ?? null,
          failedAttempts,
        },
      },
      retentionTags: [{ code: 'security', label: 'Security' }],
      contractVersion: { major: 1, minor: 0 },
    });
  }

  private isLoginAllowed(identity: AuthIdentityRecord): boolean {
    return (
      identity.status === 'active' &&
      (identity.kind === 'platform' ||
        (identity.tenantStatus === 'active' && identity.tenantId !== undefined))
    );
  }

  private resolveBranch(
    identity: AuthIdentityRecord,
    branchCode?: string,
  ): AuthIdentityRecord['branches'][number] | undefined {
    if (identity.kind !== 'tenant') {
      return undefined;
    }

    if (identity.branches.length === 0) {
      throw new PlatformError({
        code: 'auth.branch_unavailable',
        category: 'forbidden',
        messageKey: 'errors.auth.branch_unavailable',
      });
    }

    if (!branchCode) {
      return (
        identity.branches.find((branch) => branch.branchId === identity.defaultBranchId) ??
        identity.branches[0]
      );
    }

    const branch = identity.branches.find(
      (candidate) => candidate.branchCode.toLowerCase() === branchCode.trim().toLowerCase(),
    );
    if (!branch) {
      throw new PlatformError({
        code: 'auth.branch_unavailable',
        category: 'forbidden',
        messageKey: 'errors.auth.branch_unavailable',
      });
    }

    return branch;
  }

  private async enforceConcurrentSessionPolicy(userId: string): Promise<void> {
    const active = await this.authRepository.listActiveSessionsByUser(userId);
    if (!this.configuration.allowMultiDevice && active.length > 0) {
      await this.authRepository.revokeSessionsByUser(
        userId,
        'single_device_policy',
        new Date().toISOString(),
      );
      return;
    }

    if (active.length < this.configuration.maxActiveSessions) {
      return;
    }

    const sessionsToRevoke = active.slice(
      0,
      active.length - this.configuration.maxActiveSessions + 1,
    );
    for (const session of sessionsToRevoke) {
      await this.authRepository.updateSession({
        ...session,
        revokedAtUtc: new Date().toISOString(),
        revokedReason: 'session_limit_exceeded',
      });
    }
  }

  private createAccessClaims(context: PlatformContext | TenantContext): AuthAccessTokenClaims {
    return {
      tokenKind: 'access',
      sessionId: context.sessionId ?? '',
      userId: context.actorId,
      kind: context.kind,
      roleCode: context.roleCode ?? 'platform_admin',
      permissions: context.permissions ?? [],
      accessVersion: context.accessVersion ?? 1,
      tenantId: context.kind === 'tenant' ? context.tenantId : undefined,
      branchId: context.kind === 'tenant' ? context.branchId : undefined,
    };
  }

  private createTrustedContext(
    identity: AuthIdentityRecord,
    session: AuthSessionRecord,
    metadata: AuthRequestMetadata,
  ): PlatformContext | TenantContext {
    if (identity.kind === 'platform') {
      return this.trustedContextFactory.createPlatformContext({
        actorId: identity.userId,
        actorType: 'user',
        correlationId: metadata.correlationId,
        causationId: metadata.causationId,
        requestId: metadata.requestId,
        sessionId: session.sessionId,
        roleCode: identity.roleCode,
        permissions: identity.permissions,
        accessVersion: identity.accessVersion,
      });
    }

    return this.trustedContextFactory.createTenantContext({
      actorId: identity.userId,
      actorType: 'user',
      correlationId: metadata.correlationId,
      causationId: metadata.causationId,
      requestId: metadata.requestId,
      tenantId: identity.tenantId ?? 'missing-tenant',
      branchId: session.branchId,
      permissions: identity.permissions,
      accessVersion: identity.accessVersion,
      sessionId: session.sessionId,
      roleCode: identity.roleCode,
    });
  }

  private createTrustedContextFromSession(
    session: AuthSessionRecord,
    metadata: AuthRequestMetadata,
  ): PlatformContext | TenantContext {
    if (session.kind === 'platform') {
      return this.trustedContextFactory.createPlatformContext({
        actorId: session.userId,
        actorType: 'user',
        correlationId: metadata.correlationId,
        causationId: metadata.causationId,
        requestId: metadata.requestId,
        sessionId: session.sessionId,
        roleCode: session.roleCode,
        permissions: session.permissions,
        accessVersion: session.accessVersion,
      });
    }

    return this.trustedContextFactory.createTenantContext({
      actorId: session.userId,
      actorType: 'user',
      correlationId: metadata.correlationId,
      causationId: metadata.causationId,
      requestId: metadata.requestId,
      tenantId: session.tenantId ?? 'missing-tenant',
      branchId: session.branchId,
      permissions: session.permissions,
      accessVersion: session.accessVersion,
      sessionId: session.sessionId,
      roleCode: session.roleCode,
    });
  }

  private createTokenResponse(
    accessToken: string,
    accessTokenExpiresAt: number,
    refreshToken: string,
    refreshTokenExpiresAt: number,
  ): AuthTokens {
    return {
      accessToken,
      refreshToken,
      accessTokenExpiresAtUtc: new Date(accessTokenExpiresAt * 1000).toISOString(),
      refreshTokenExpiresAtUtc: new Date(refreshTokenExpiresAt * 1000).toISOString(),
    };
  }

  private createServiceContext(metadata: AuthRequestMetadata): PlatformContext {
    return this.trustedContextFactory.createPlatformContext({
      actorId: 'auth-service',
      actorType: 'service',
      correlationId: metadata.correlationId,
      causationId: metadata.causationId,
      requestId: metadata.requestId,
    });
  }

  private createTrackerKey(
    context: 'platform' | 'tenant',
    identifier: string,
    tenantSlug?: string,
  ): string {
    return `${context}:${tenantSlug?.trim().toLowerCase() ?? '-'}:${normalizeIdentifier(identifier)}`;
  }

  private assertTokenEnvelope(envelope: SignedTokenEnvelope<unknown>): void {
    if (
      envelope.issuer !== this.configuration.issuer ||
      envelope.audience !== this.configuration.audience
    ) {
      throw new PlatformError({
        code: 'auth.token_invalid',
        category: 'unauthenticated',
        messageKey: 'errors.auth.token_invalid',
      });
    }
  }

  private async loadIdentityForContext(context: TrustedContext): Promise<AuthIdentityRecord> {
    const identity = await this.authRepository.findIdentityByUserId(context.actorId);
    if (identity) {
      return identity;
    }

    throw new PlatformError({
      code: 'auth.identity_not_found',
      category: 'not_found',
      messageKey: 'errors.auth.identity_not_found',
    });
  }

  private toSyntheticSession(identity: AuthIdentityRecord): AuthSessionRecord {
    const branch = identity.branches[0];
    const timestamp = new Date().toISOString();
    return {
      sessionId: `synthetic-${identity.userId}`,
      familyId: `synthetic-${identity.userId}`,
      userId: identity.userId,
      kind: identity.kind,
      roleCode: identity.roleCode,
      permissions: identity.permissions,
      accessVersion: identity.accessVersion,
      tenantId: identity.tenantId,
      tenantSlug: identity.tenantSlug,
      tenantName: identity.tenantName,
      branchId: branch?.branchId,
      branchCode: branch?.branchCode,
      branchName: branch?.branchName,
      refreshTokenHash: 'n/a',
      expiresAtUtc: timestamp,
      createdAtUtc: timestamp,
      lastActivityAtUtc: timestamp,
    };
  }

  private async recordSecurityEvent(
    action: string,
    session: AuthSessionRecord,
    metadata: AuthRequestMetadata,
  ): Promise<void> {
    await this.auditService.recordAudit({
      sourceObligation: `auth:${action}:${session.sessionId}:${metadata.requestId}`,
      idempotencyKey: `auth:${action}:${session.sessionId}:${metadata.requestId}`,
      module: 'auth',
      action,
      classification: 'security',
      actor: { actorId: session.userId, actorType: 'user' },
      target: { targetId: session.sessionId, targetType: 'auth_session' },
      context: this.createTrustedContextFromSession(session, metadata),
      retentionTags: [{ code: 'security', label: 'Security' }],
      contractVersion: { major: 1, minor: 0 },
    });
  }
}
