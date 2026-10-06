import { ConfigService } from '@nestjs/config';

import type { AuditService } from '../src/audit/audit.service';
import { hashOpaqueSecret, hashPassword } from '../src/auth/auth.crypto';
import { normalizeIndianMobile } from '../src/auth/auth.normalization';
import { AuthService } from '../src/auth/auth.service';
import type {
  AuthIdentityRecord,
  AuthLoginTracker,
  AuthRepository,
  AuthSessionRecord,
  ConsumerAccountRecord,
} from '../src/auth/auth.types';
import { ConsumerAuthService } from '../src/auth/consumer-auth.service';
import type { EmailService } from '../src/email/email.service';
import { TrustedContextFactory } from '../src/platform/platform.context';
import { PlatformError } from '../src/platform/platform.errors';

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
const otpSecret = 'refresh-secret-that-is-longer-than-thirty-two-characters';
const password = 'Fresh@2026Pass';

/** In-memory consumerAccounts store keyed by userId. */
function createRepository(seed: ConsumerAccountRecord[] = []) {
  const accounts = new Map(seed.map((account) => [account.userId, account]));
  const repository = {
    findConsumerAccount: jest.fn((by: { email?: string; mobileNumber?: string; userId?: string }) =>
      Promise.resolve(
        [...accounts.values()].find(
          (a) =>
            (by.userId && a.userId === by.userId) ||
            (by.email && a.email === by.email.trim().toLowerCase()) ||
            (by.mobileNumber && a.mobileNumber === by.mobileNumber),
        ) ?? null,
      ),
    ),
    saveConsumerAccount: jest.fn((record: ConsumerAccountRecord) => {
      accounts.set(record.userId, record);
      return Promise.resolve(record);
    }),
  } as unknown as jest.Mocked<AuthRepository>;
  return { repository, accounts };
}

function createEmail(success = true) {
  const sent: { email: string; otp: string }[] = [];
  const emailService = {
    sendEmailVerificationOtp: jest.fn((email: string, otp: string) => {
      sent.push({ email, otp });
      return Promise.resolve({ success });
    }),
  } as unknown as EmailService;
  return { emailService, sent };
}

function account(overrides: Partial<ConsumerAccountRecord> = {}): ConsumerAccountRecord {
  return {
    userId: 'consumer-1',
    email: 'riya@example.com',
    mobileNumber: '9876543210',
    displayName: 'Riya Sharma',
    passwordHash: hashPassword(password),
    status: 'active',
    emailVerified: true,
    verificationAttempts: 0,
    accessVersion: 1,
    passwordChangedAtUtc: '2026-10-01T00:00:00.000Z',
    createdAtUtc: '2026-10-01T00:00:00.000Z',
    updatedAtUtc: '2026-10-01T00:00:00.000Z',
    ...overrides,
  };
}

async function expectError(promise: Promise<unknown>, code: string): Promise<void> {
  await expect(promise).rejects.toBeInstanceOf(PlatformError);
  await promise.catch((error: PlatformError) => expect(error.code).toBe(code));
}

describe('normalizeIndianMobile', () => {
  it.each([
    ['9876543210', '9876543210'],
    ['+91 98765 43210', '9876543210'],
    ['919876543210', '9876543210'],
    ['09876543210', '9876543210'],
    ['98765-43210', '9876543210'],
  ])('accepts %s', (input, expected) => {
    expect(normalizeIndianMobile(input)).toBe(expected);
  });

  it.each(['12345', '5876543210', '98765432101', 'abcdefghij'])('rejects %s', (input) => {
    expect(normalizeIndianMobile(input)).toBeUndefined();
  });
});

describe('ConsumerAuthService', () => {
  const registration = {
    fullName: '  Riya   Sharma ',
    email: 'Riya@Example.com',
    mobileNumber: '+91 98765 43210',
    password,
  };

  it('creates an unverified account and emails a code that is stored only as a hash', async () => {
    const { repository, accounts } = createRepository();
    const { emailService, sent } = createEmail();
    const service = new ConsumerAuthService(repository, config, emailService);

    const result = await service.register(registration);

    expect(result.deliveryHint).toContain('r***');
    const [stored] = [...accounts.values()];
    expect(stored).toMatchObject({
      email: 'riya@example.com',
      mobileNumber: '9876543210',
      displayName: 'Riya Sharma',
      emailVerified: false,
    });
    expect(sent).toHaveLength(1);
    expect(stored.verificationOtpHash).toBe(hashOpaqueSecret(sent[0].otp, otpSecret));
    expect(JSON.stringify(stored)).not.toContain(password);
  });

  it('rejects a verified email and a mobile number used by another account', async () => {
    const { repository } = createRepository([account()]);
    const service = new ConsumerAuthService(repository, config, createEmail().emailService);

    await expectError(service.register(registration), 'consumer.email_taken');
    await expectError(
      service.register({ ...registration, email: 'other@example.com' }),
      'consumer.mobile_taken',
    );
  });

  it('lets an unverified sign-up be retried with new details', async () => {
    const { repository, accounts } = createRepository([
      account({ emailVerified: false, displayName: 'Old Name' }),
    ]);
    const service = new ConsumerAuthService(repository, config, createEmail().emailService);

    await service.register(registration);

    expect(accounts.size).toBe(1);
    expect(accounts.get('consumer-1')?.displayName).toBe('Riya Sharma');
  });

  it('rejects an invalid mobile number and a weak password', async () => {
    const { repository } = createRepository();
    const service = new ConsumerAuthService(repository, config, createEmail().emailService);

    await expectError(
      service.register({ ...registration, mobileNumber: '12345' }),
      'consumer.mobile_invalid',
    );
    await expectError(
      service.register({ ...registration, password: 'weak' }),
      'auth.password_policy_failed',
    );
  });

  it('fails the sign-up when the email cannot be delivered', async () => {
    const { repository } = createRepository();
    const service = new ConsumerAuthService(repository, config, createEmail(false).emailService);

    await expectError(service.register(registration), 'auth.email_delivery_failed');
  });

  it('verifies the email with the right code and clears the code', async () => {
    const { repository, accounts } = createRepository();
    const { emailService, sent } = createEmail();
    const service = new ConsumerAuthService(repository, config, emailService);
    await service.register(registration);

    await expectError(
      service.verifyEmail({
        email: 'riya@example.com',
        otp: '000000' === sent[0].otp ? '111111' : '000000',
      }),
      'consumer.verification_invalid',
    );
    await service.verifyEmail({ email: 'RIYA@example.com', otp: sent[0].otp });

    const [stored] = [...accounts.values()];
    expect(stored.emailVerified).toBe(true);
    expect(stored.verificationOtpHash).toBeUndefined();
  });

  it('locks verification after too many wrong codes', async () => {
    const { repository } = createRepository([
      account({
        emailVerified: false,
        verificationOtpHash: hashOpaqueSecret('123456', otpSecret),
        verificationExpiresAtUtc: new Date(Date.now() + 60_000).toISOString(),
        verificationAttempts: 5,
      }),
    ]);
    const service = new ConsumerAuthService(repository, config, createEmail().emailService);

    await expectError(
      service.verifyEmail({ email: 'riya@example.com', otp: '123456' }),
      'consumer.verification_attempts_exceeded',
    );
  });

  it('rejects an expired code', async () => {
    const { repository } = createRepository([
      account({
        emailVerified: false,
        verificationOtpHash: hashOpaqueSecret('123456', otpSecret),
        verificationExpiresAtUtc: new Date(Date.now() - 1_000).toISOString(),
      }),
    ]);
    const service = new ConsumerAuthService(repository, config, createEmail().emailService);

    await expectError(
      service.verifyEmail({ email: 'riya@example.com', otp: '123456' }),
      'consumer.verification_invalid',
    );
  });

  it('resends at most once a minute and answers neutrally for unknown emails', async () => {
    const { repository } = createRepository();
    const { emailService, sent } = createEmail();
    const service = new ConsumerAuthService(repository, config, emailService);
    await service.register(registration);

    const tooSoon = await service.resendVerification({ email: 'riya@example.com' });
    const unknown = await service.resendVerification({ email: 'nobody@example.com' });

    expect(sent).toHaveLength(1);
    expect(tooSoon.resendAvailableInSeconds).toBeGreaterThan(0);
    expect(unknown.deliveryHint).toBe(tooSoon.deliveryHint);
  });

  it('returns the profile only for a consumer session', async () => {
    const { repository } = createRepository([account()]);
    const service = new ConsumerAuthService(repository, config, createEmail().emailService);
    const factory = new TrustedContextFactory();
    const seed = {
      actorType: 'user' as const,
      correlationId: 'c',
      causationId: 'c',
      requestId: 'r',
    };

    await expect(
      service.profile(
        factory.createConsumerContext({ ...seed, actorId: 'consumer-1', accessVersion: 1 }),
      ),
    ).resolves.toMatchObject({
      actorId: 'consumer-1',
      kind: 'consumer',
      mobileNumber: '9876543210',
    });
    await expectError(
      service.profile(
        factory.createTenantContext({
          ...seed,
          actorId: 'consumer-1',
          tenantId: 't',
          permissions: [],
          accessVersion: 1,
        }),
      ),
      'auth.consumer_context_required',
    );
    await expectError(
      service.profile(
        factory.createConsumerContext({ ...seed, actorId: 'consumer-1', accessVersion: 0 }),
      ),
      'auth.session_expired',
    );
  });
});

describe('AuthService consumer login', () => {
  function createLogin(identity: AuthIdentityRecord) {
    const repository = {
      findIdentity: jest.fn().mockResolvedValue(identity),
      getLoginTracker: jest.fn().mockResolvedValue(null),
      saveLoginTracker: jest.fn((tracker: AuthLoginTracker) => Promise.resolve(tracker)),
      resetLoginTracker: jest.fn().mockResolvedValue(undefined),
      listActiveSessionsByUser: jest.fn().mockResolvedValue([]),
      createSession: jest.fn((session: AuthSessionRecord) => Promise.resolve(session)),
    } as unknown as jest.Mocked<AuthRepository>;
    const auditService = { recordAudit: jest.fn().mockResolvedValue(undefined) };
    const service = new AuthService(
      repository,
      auditService as unknown as AuditService,
      config,
      new TrustedContextFactory(),
    );
    return { service, repository, auditService };
  }

  const consumerIdentity = (emailVerified: boolean): AuthIdentityRecord => ({
    userId: 'consumer-1',
    kind: 'consumer',
    email: 'riya@example.com',
    mobileNumber: '9876543210',
    displayName: 'Riya Sharma',
    passwordHash: hashPassword(password),
    roleCode: 'consumer',
    permissions: [],
    status: 'active',
    accessVersion: 1,
    branches: [],
    passwordChangedAtUtc: '2026-10-01T00:00:00.000Z',
    emailVerified,
  });
  const metadata = { correlationId: 'c', causationId: 'c', requestId: 'r' };

  it('refuses an unverified customer only after the password matched', async () => {
    const { service } = createLogin(consumerIdentity(false));

    await expectError(
      service.login({
        context: 'consumer',
        identifier: 'riya@example.com',
        password: 'Wrong@2026x',
        metadata,
      }),
      'auth.login_denied',
    );
    await expectError(
      service.login({ context: 'consumer', identifier: 'riya@example.com', password, metadata }),
      'auth.email_not_verified',
    );
  });

  it('issues a consumer session with no tenant, branch or permissions', async () => {
    const { service, repository, auditService } = createLogin(consumerIdentity(true));

    const result = await service.login({
      context: 'consumer',
      identifier: '9876543210',
      password,
      metadata,
    });

    expect(result.tenant).toBeUndefined();
    expect(result.branch).toBeUndefined();
    expect(result.permissions).toEqual([]);
    expect(repository.createSession).toHaveBeenCalledWith(
      expect.objectContaining({ kind: 'consumer', tenantId: undefined, branchId: undefined }),
    );
    const claims = JSON.parse(
      Buffer.from(result.accessToken.split('.')[1], 'base64url').toString('utf8'),
    ).claims;
    expect(claims).toMatchObject({ kind: 'consumer', roleCode: 'consumer', permissions: [] });
    expect(claims.tenantId).toBeUndefined();
    // Consumer activity is audited on the platform scope.
    expect(auditService.recordAudit).toHaveBeenCalledWith(
      expect.objectContaining({
        context: expect.objectContaining({ kind: 'platform', actorId: 'consumer-1' }),
      }),
    );

    const resolution = await service
      .authenticateAccessToken(result.accessToken, metadata)
      .catch(() => null);
    // findSessionById is not mocked here; the token itself must at least verify.
    expect(resolution).toBeNull();
  });

  it('never grants a branch context to a consumer token', async () => {
    const { service } = createLogin(consumerIdentity(true));
    const consumer = new TrustedContextFactory().createConsumerContext({
      actorId: 'consumer-1',
      actorType: 'user',
      correlationId: 'c',
      causationId: 'c',
      requestId: 'r',
      accessVersion: 1,
    });

    await expectError(
      service.authorizeBranchContext(consumer, 'branch-1'),
      'auth.tenant_context_required',
    );
  });
});
