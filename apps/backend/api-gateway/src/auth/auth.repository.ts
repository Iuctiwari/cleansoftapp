import { Injectable, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { hashPassword } from './auth.crypto';
import type {
  AuthIdentityRecord,
  AuthLoginContext,
  AuthLoginTracker,
  AuthNotificationIntent,
  AuthRepository,
  AuthSeedAccount,
  AuthSessionRecord,
  PasswordResetRecord,
} from './auth.types';

function normalizeIdentifier(identifier: string): string {
  return identifier.trim().toLowerCase();
}

function buildIdentityKey(
  context: AuthLoginContext,
  identifier: string,
  tenantSlug?: string,
): string {
  return `${context}:${tenantSlug?.trim().toLowerCase() ?? '-'}:${normalizeIdentifier(identifier)}`;
}

function createDefaultSeedAccounts(): readonly AuthSeedAccount[] {
  return [
    {
      userId: 'platform-admin-1',
      kind: 'platform',
      email: 'platform.admin@nexoraa.local',
      mobileNumber: '9000000001',
      displayName: 'Platform Administrator',
      password: 'Platform#123',
      roleCode: 'platform_admin',
      permissions: ['platform:read', 'platform:write', 'audit:read', 'jobs:manage'],
    },
    {
      userId: 'tenant-owner-1',
      kind: 'tenant',
      email: 'owner@alpha.nexoraa.local',
      mobileNumber: '9000000002',
      displayName: 'Tenant Owner Alpha',
      password: 'Tenant#123',
      roleCode: 'tenant_owner',
      permissions: ['orders:read', 'orders:write', 'audit:read'],
      tenantId: 'tenant-alpha',
      tenantSlug: 'alpha',
      tenantName: 'Alpha CleanSoft',
      branches: [
        { branchId: 'branch-alpha-main', branchCode: 'main', branchName: 'Main Branch' },
        { branchId: 'branch-alpha-north', branchCode: 'north', branchName: 'North Branch' },
      ],
      defaultBranchId: 'branch-alpha-main',
    },
  ];
}

function toIdentityRecord(seed: AuthSeedAccount): AuthIdentityRecord {
  return {
    userId: seed.userId,
    kind: seed.kind,
    email: seed.email.trim().toLowerCase(),
    mobileNumber: seed.mobileNumber?.trim(),
    displayName: seed.displayName,
    passwordHash: hashPassword(seed.password),
    roleCode: seed.roleCode,
    permissions: Object.freeze([...seed.permissions]),
    status: seed.status ?? 'active',
    accessVersion: seed.accessVersion ?? 1,
    tenantId: seed.tenantId,
    tenantSlug: seed.tenantSlug,
    tenantName: seed.tenantName,
    tenantStatus: seed.tenantStatus ?? 'active',
    branches: Object.freeze([...(seed.branches ?? [])]),
    defaultBranchId: seed.defaultBranchId,
    passwordChangedAtUtc: seed.passwordChangedAtUtc ?? new Date().toISOString(),
  };
}

@Injectable()
export class InMemoryAuthRepository implements AuthRepository {
  private readonly identitiesByLocator = new Map<string, AuthIdentityRecord>();
  private readonly identitiesByUserId = new Map<string, AuthIdentityRecord>();
  private readonly loginTrackers = new Map<string, AuthLoginTracker>();
  private readonly sessionsById = new Map<string, AuthSessionRecord>();
  private readonly passwordResetsByUserId = new Map<string, PasswordResetRecord>();
  private readonly notifications = new Map<string, AuthNotificationIntent>();

  constructor(
    private readonly configService: ConfigService,
    @Optional() seedAccounts?: readonly AuthSeedAccount[],
  ) {
    const configuredAccounts = this.loadConfiguredAccounts();
    const effectiveSeeds =
      configuredAccounts ?? seedAccounts ?? this.loadDefaultSeedAccounts(this.configService);
    for (const seed of effectiveSeeds) {
      this.persistIdentity(toIdentityRecord(seed));
    }
  }

  async findIdentity(
    context: AuthLoginContext,
    identifier: string,
    tenantSlug?: string,
  ): Promise<AuthIdentityRecord | null> {
    return this.identitiesByLocator.get(buildIdentityKey(context, identifier, tenantSlug)) ?? null;
  }

  async findIdentityByUserId(userId: string): Promise<AuthIdentityRecord | null> {
    return this.identitiesByUserId.get(userId) ?? null;
  }

  async resetLoginTracker(trackerKey: string): Promise<void> {
    this.loginTrackers.delete(trackerKey);
  }

  async getLoginTracker(trackerKey: string): Promise<AuthLoginTracker | null> {
    return this.loginTrackers.get(trackerKey) ?? null;
  }

  async saveLoginTracker(tracker: AuthLoginTracker): Promise<AuthLoginTracker> {
    this.loginTrackers.set(tracker.trackerKey, tracker);
    return tracker;
  }

  async replaceIdentity(identity: AuthIdentityRecord): Promise<AuthIdentityRecord> {
    this.persistIdentity(identity);
    return identity;
  }

  async createSession(session: AuthSessionRecord): Promise<AuthSessionRecord> {
    this.sessionsById.set(session.sessionId, session);
    return session;
  }

  async updateSession(session: AuthSessionRecord): Promise<AuthSessionRecord> {
    this.sessionsById.set(session.sessionId, session);
    return session;
  }

  async findSessionById(sessionId: string): Promise<AuthSessionRecord | null> {
    return this.sessionsById.get(sessionId) ?? null;
  }

  async listActiveSessionsByUser(userId: string): Promise<readonly AuthSessionRecord[]> {
    return [...this.sessionsById.values()]
      .filter((session) => session.userId === userId && !session.revokedAtUtc)
      .sort((left, right) => left.createdAtUtc.localeCompare(right.createdAtUtc));
  }

  async revokeSessionsByFamily(
    familyId: string,
    reason: string,
    revokedAtUtc: string,
  ): Promise<readonly AuthSessionRecord[]> {
    const revoked: AuthSessionRecord[] = [];
    for (const session of this.sessionsById.values()) {
      if (session.familyId !== familyId || session.revokedAtUtc) {
        continue;
      }

      const updated: AuthSessionRecord = {
        ...session,
        revokedAtUtc,
        revokedReason: reason,
        reuseDetectedAtUtc:
          reason === 'refresh_token_reuse_detected' ? revokedAtUtc : session.reuseDetectedAtUtc,
      };
      this.sessionsById.set(updated.sessionId, updated);
      revoked.push(updated);
    }

    return revoked;
  }

  async revokeSessionsByUser(
    userId: string,
    reason: string,
    revokedAtUtc: string,
    exceptSessionId?: string,
  ): Promise<readonly AuthSessionRecord[]> {
    const revoked: AuthSessionRecord[] = [];
    for (const session of this.sessionsById.values()) {
      if (
        session.userId !== userId ||
        session.revokedAtUtc ||
        session.sessionId === exceptSessionId
      ) {
        continue;
      }

      const updated: AuthSessionRecord = {
        ...session,
        revokedAtUtc,
        revokedReason: reason,
      };
      this.sessionsById.set(updated.sessionId, updated);
      revoked.push(updated);
    }

    return revoked;
  }

  async upsertPasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord> {
    this.passwordResetsByUserId.set(record.userId, record);
    return record;
  }

  async findActivePasswordResetByUser(userId: string): Promise<PasswordResetRecord | null> {
    return this.passwordResetsByUserId.get(userId) ?? null;
  }

  async findActivePasswordResetByLocator(
    context: AuthLoginContext,
    identifier: string,
    tenantSlug?: string,
  ): Promise<PasswordResetRecord | null> {
    const identity = await this.findIdentity(context, identifier, tenantSlug);
    if (!identity) {
      return null;
    }

    return this.findActivePasswordResetByUser(identity.userId);
  }

  async consumePasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord> {
    const updated: PasswordResetRecord = { ...record, consumed: true };
    this.passwordResetsByUserId.set(updated.userId, updated);
    return updated;
  }

  async updatePasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord> {
    this.passwordResetsByUserId.set(record.userId, record);
    return record;
  }

  async recordNotification(intent: AuthNotificationIntent): Promise<AuthNotificationIntent> {
    this.notifications.set(intent.notificationId, intent);
    return intent;
  }

  createTrackerKey(context: AuthLoginContext, identifier: string, tenantSlug?: string): string {
    return buildIdentityKey(context, identifier, tenantSlug);
  }

  private persistIdentity(identity: AuthIdentityRecord): void {
    this.identitiesByUserId.set(identity.userId, identity);
    this.identitiesByLocator.set(
      buildIdentityKey(identity.kind, identity.email, identity.tenantSlug),
      identity,
    );
    if (identity.mobileNumber) {
      this.identitiesByLocator.set(
        buildIdentityKey(identity.kind, identity.mobileNumber, identity.tenantSlug),
        identity,
      );
    }
  }

  private loadConfiguredAccounts(): readonly AuthSeedAccount[] | null {
    const raw = this.configService.get<string>('AUTH_BOOTSTRAP_ACCOUNTS_JSON');
    if (!raw || raw.trim().length === 0) {
      return null;
    }

    const parsed = JSON.parse(raw) as readonly AuthSeedAccount[];
    return parsed;
  }

  private loadDefaultSeedAccounts(configService: ConfigService): readonly AuthSeedAccount[] {
    const environment = configService.get<string>('NODE_ENV') ?? 'development';
    return environment === 'production' ? [] : createDefaultSeedAccounts();
  }
}
