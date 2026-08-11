import { createHash } from 'node:crypto';

import { ConfigService } from '@nestjs/config';

import type { AuditService } from '../src/audit/audit.service';
import { hashPassword, verifyPassword } from '../src/auth/auth.crypto';
import { AuthService } from '../src/auth/auth.service';
import type {
  AuthIdentityRecord,
  AuthLoginTracker,
  AuthRepository,
  AuthSessionRecord,
} from '../src/auth/auth.types';
import { PlatformError } from '../src/platform/platform.errors';
import { TrustedContextFactory } from '../src/platform/platform.context';

const password = 'Fresh@2026Pass';

function legacyPasswordHash(): string {
  return createHash('sha256').update(`nexoraa-tenant-v1${password}`).digest('hex');
}

function tenantIdentity(passwordHash: string): AuthIdentityRecord {
  return {
    userId: 'owner-1',
    kind: 'tenant',
    email: 'owner@example.com',
    mobileNumber: '+919876543210',
    displayName: 'Owner Name',
    passwordHash,
    roleCode: 'tenant_owner',
    permissions: Object.freeze(['orders:read']),
    status: 'active',
    accessVersion: 1,
    tenantId: 'tenant-1',
    tenantSlug: 'fresh-care',
    tenantName: 'Fresh Care',
    tenantStatus: 'active',
    branches: Object.freeze([
      {
        branchId: 'branch-1',
        branchCode: 'head-office',
        branchName: 'Head Office',
      },
    ]),
    defaultBranchId: 'branch-1',
    passwordChangedAtUtc: '2026-08-11T00:00:00.000Z',
  };
}

function createSubject(passwordHash = legacyPasswordHash()): {
  readonly repository: jest.Mocked<AuthRepository>;
  readonly service: AuthService;
} {
  const identity = tenantIdentity(passwordHash);
  const repository = {
    findIdentity: jest.fn().mockResolvedValue(identity),
    getLoginTracker: jest.fn().mockResolvedValue(null),
    saveLoginTracker: jest.fn((tracker: AuthLoginTracker) => Promise.resolve(tracker)),
    resetLoginTracker: jest.fn().mockResolvedValue(undefined),
    listActiveSessionsByUser: jest.fn().mockResolvedValue([]),
    replaceIdentity: jest.fn((replacement: AuthIdentityRecord) => Promise.resolve(replacement)),
    createSession: jest.fn((session: AuthSessionRecord) => Promise.resolve(session)),
  } as unknown as jest.Mocked<AuthRepository>;
  const auditService = {
    recordAudit: jest.fn().mockResolvedValue(undefined),
  } as unknown as AuditService;
  const config = new ConfigService({
    APP_NAME: 'Nexoraa CleanSoft',
    AUTH_ACCESS_TOKEN_SECRET: 'access-secret-that-is-longer-than-thirty-two-characters',
    AUTH_REFRESH_TOKEN_SECRET: 'refresh-secret-that-is-longer-than-thirty-two-characters',
    AUTH_ACCESS_TOKEN_TTL_SECONDS: '900',
    AUTH_REFRESH_TOKEN_TTL_SECONDS: '604800',
    AUTH_LOGIN_MAX_ATTEMPTS: '5',
    AUTH_LOCKOUT_SECONDS: '900',
    AUTH_OTP_TTL_SECONDS: '600',
    AUTH_OTP_MAX_ATTEMPTS: '5',
    AUTH_MAX_ACTIVE_SESSIONS: '3',
    AUTH_ALLOW_MULTI_DEVICE: 'true',
  });

  return {
    repository,
    service: new AuthService(repository, auditService, config, new TrustedContextFactory()),
  };
}

const metadata = {
  correlationId: '11111111-1111-4111-8111-111111111111',
  causationId: '22222222-2222-4222-8222-222222222222',
  requestId: '33333333-3333-4333-8333-333333333333',
};

describe('tenant owner login', () => {
  it('authenticates a legacy owner, upgrades its hash, and issues tokens', async () => {
    const { repository, service } = createSubject();

    const response = await service.login({
      context: 'tenant',
      identifier: ' OWNER@EXAMPLE.COM ',
      password,
      metadata,
    });

    expect(response.accessToken).toBeTruthy();
    expect(response.refreshToken).toBeTruthy();
    expect(response.tenant?.tenantId).toBe('tenant-1');
    expect(repository.createSession.mock.calls).toHaveLength(1);
    expect(repository.replaceIdentity.mock.calls).toHaveLength(1);
    const upgraded = repository.replaceIdentity.mock.calls[0][0];
    expect(upgraded.passwordHash).toMatch(/^scrypt\$/);
    expect(verifyPassword(password, upgraded.passwordHash)).toBe(true);
  });

  it('still rejects an invalid password without issuing a session', async () => {
    const { repository, service } = createSubject(hashPassword(password));

    await expect(
      service.login({
        context: 'tenant',
        identifier: 'owner@example.com',
        password: 'incorrect-password',
        metadata,
      }),
    ).rejects.toMatchObject<Partial<PlatformError>>({
      code: 'auth.login_denied',
      statusCode: 401,
    });
    expect(repository.createSession.mock.calls).toHaveLength(0);
    expect(repository.replaceIdentity.mock.calls).toHaveLength(0);
  });
});
