import { createSign, generateKeyPairSync } from 'node:crypto';

import { ConfigService } from '@nestjs/config';

import { hashPassword } from '../src/auth/auth.crypto';
import type { AuthRepository, ConsumerAccountRecord } from '../src/auth/auth.types';
import { ConsumerAuthService } from '../src/auth/consumer-auth.service';
import { FirebaseIdTokenVerifier } from '../src/auth/firebase-id-token.verifier';
import { PlatformError } from '../src/platform/platform.errors';

const PROJECT = 'nexoraa-test-project';
const { publicKey, privateKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const otherKey = generateKeyPairSync('rsa', { modulusLength: 2048 });
const publicPem = publicKey.export({ type: 'spki', format: 'pem' }).toString();
const NOW = 1_800_000_000;

/** A verifier that trusts our local key instead of downloading Google's certificates. */
class LocalKeyVerifier extends FirebaseIdTokenVerifier {
  protected override certs(): Promise<Record<string, string>> {
    return Promise.resolve({ 'test-kid': publicPem });
  }
}

const config = (projectId?: string) =>
  new ConfigService({ ...(projectId ? { FIREBASE_PROJECT_ID: projectId } : {}) });

function token(
  claims: Record<string, unknown> = {},
  { key = privateKey, kid = 'test-kid' }: { key?: typeof privateKey; kid?: string } = {},
): string {
  const b64 = (value: unknown) => Buffer.from(JSON.stringify(value)).toString('base64url');
  const header = b64({ alg: 'RS256', kid, typ: 'JWT' });
  const payload = b64({
    iss: `https://securetoken.google.com/${PROJECT}`,
    aud: PROJECT,
    sub: 'firebase-uid-1',
    iat: NOW - 10,
    exp: NOW + 3600,
    phone_number: '+919811200001',
    ...claims,
  });
  const signature = createSign('RSA-SHA256').update(`${header}.${payload}`).sign(key).toString('base64url');
  return `${header}.${payload}.${signature}`;
}

describe('FirebaseIdTokenVerifier', () => {
  const verifier = new LocalKeyVerifier(config(PROJECT));

  it('accepts a genuine phone-login token and returns the number', async () => {
    await expect(verifier.verify(token(), NOW)).resolves.toEqual({
      uid: 'firebase-uid-1',
      phoneNumber: '+919811200001',
    });
  });

  it.each([
    ['a token signed with another key', () => token({}, { key: otherKey.privateKey }), 'bad_signature'],
    ['an unknown key id', () => token({}, { kid: 'nope' }), 'unknown_key'],
    ['another Firebase project', () => token({ aud: 'someone-elses-project' }), 'wrong_audience'],
    ['the wrong issuer', () => token({ iss: 'https://evil.example.com' }), 'wrong_issuer'],
    ['an expired token', () => token({ exp: NOW - 3600 }), 'expired'],
    ['a token without a phone number', () => token({ phone_number: undefined }), 'not_a_phone_login'],
    ['garbage', () => 'not-a-jwt', 'malformed'],
  ])('refuses %s', async (_label, make, reason) => {
    await expect(verifier.verify(make(), NOW)).rejects.toMatchObject({ reason });
  });

  it('is off until the Firebase project is configured', async () => {
    const off = new LocalKeyVerifier(config());
    expect(off.isEnabled()).toBe(false);
    await expect(off.verify(token(), NOW)).rejects.toMatchObject({ reason: 'not_configured' });
  });
});

describe('ConsumerAuthService.verifyPhone', () => {
  const settings = new ConfigService({
    AUTH_REFRESH_TOKEN_SECRET: 'refresh-secret-that-is-longer-than-thirty-two-characters',
    AUTH_OTP_TTL_SECONDS: '600',
    AUTH_OTP_MAX_ATTEMPTS: '5',
  });

  function setup(overrides: Partial<ConsumerAccountRecord> = {}, projectId = PROJECT) {
    const stored: ConsumerAccountRecord[] = [
      {
        userId: 'consumer-1',
        email: 'riya@example.com',
        mobileNumber: '9811200001',
        displayName: 'Riya',
        passwordHash: hashPassword('Fresh@2026Pass'),
        status: 'active',
        emailVerified: false,
        verificationAttempts: 0,
        accessVersion: 1,
        passwordChangedAtUtc: 'x',
        createdAtUtc: 'x',
        updatedAtUtc: 'x',
        ...overrides,
      },
    ];
    const repository = {
      findConsumerAccount: jest.fn((by: { email?: string }) =>
        Promise.resolve(stored.find((a) => a.email === by.email?.trim().toLowerCase()) ?? null),
      ),
      saveConsumerAccount: jest.fn((record: ConsumerAccountRecord) => {
        stored[0] = record;
        return Promise.resolve(record);
      }),
    } as unknown as jest.Mocked<AuthRepository>;
    const service = new ConsumerAuthService(repository, settings, undefined, new LocalKeyVerifier(config(projectId)));
    return { service, stored, repository };
  }

  async function code(promise: Promise<unknown>): Promise<string> {
    return promise.then(
      () => 'ok',
      (error: PlatformError) => error.code,
    );
  }

  it('verifies the account when the phone proves the number on the account', async () => {
    const { service, stored } = setup();
    await service.verifyPhone({ email: 'Riya@Example.com', idToken: token({ iat: 1, exp: 99_999_999_999 }) });
    expect(stored[0]).toMatchObject({ emailVerified: true });
    expect(stored[0]?.phoneVerifiedAtUtc).toBeDefined();
  });

  it('refuses a different phone number, with the same answer as a bad code', async () => {
    const { service, stored } = setup();
    const other = token({ phone_number: '+919000000009', iat: 1, exp: 99_999_999_999 });
    expect(await code(service.verifyPhone({ email: 'riya@example.com', idToken: other }))).toBe('consumer.verification_invalid');
    expect(stored[0]?.emailVerified).toBe(false);
  });

  it('refuses an unknown email and a forged token the same way', async () => {
    const { service } = setup();
    const good = token({ iat: 1, exp: 99_999_999_999 });
    expect(await code(service.verifyPhone({ email: 'nobody@example.com', idToken: good }))).toBe('consumer.verification_invalid');
    const forged = token({ iat: 1, exp: 99_999_999_999 }, { key: otherKey.privateKey });
    expect(await code(service.verifyPhone({ email: 'riya@example.com', idToken: forged }))).toBe('consumer.verification_invalid');
  });

  it('says phone verification is unavailable until Firebase is configured', async () => {
    const { service } = setup({}, '');
    expect(await code(service.verifyPhone({ email: 'riya@example.com', idToken: 'x' }))).toBe('consumer.phone_verification_unavailable');
  });
});
