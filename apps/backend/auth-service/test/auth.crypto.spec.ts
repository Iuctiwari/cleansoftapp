import { createHash } from 'node:crypto';

import { hashPassword as hashTenantPassword } from '../../tenant-service/src/tenant/tenant.crypto';
import {
  signToken,
  verifyLegacyTenantPassword,
  verifyPassword,
  verifyToken,
} from '../src/auth/auth.crypto';
import { PlatformError } from '../src/platform/platform.errors';

describe('authentication tokens', () => {
  const secret = 'test-token-secret-that-is-longer-than-thirty-two-characters';
  const issuedAt = new Date('2026-08-11T10:00:00.000Z');

  it('accepts an unexpired token with a valid signature', () => {
    const signed = signToken(
      'access',
      'user-1',
      { sessionId: 'session-1' },
      {
        issuer: 'Nexoraa CleanSoft',
        audience: 'api-gateway',
        secret,
        expiresInSeconds: 900,
        now: issuedAt,
      },
    );

    expect(
      verifyToken(signed.token, secret, 'access', new Date('2026-08-11T10:10:00.000Z')),
    ).toMatchObject({ subject: 'user-1', tokenKind: 'access' });
  });

  it('rejects an expired token as unauthenticated', () => {
    const signed = signToken(
      'access',
      'user-1',
      { sessionId: 'session-1' },
      {
        issuer: 'Nexoraa CleanSoft',
        audience: 'api-gateway',
        secret,
        expiresInSeconds: 60,
        now: issuedAt,
      },
    );

    try {
      verifyToken(signed.token, secret, 'access', new Date('2026-08-11T10:02:00.000Z'));
      throw new Error('Expected token verification to fail');
    } catch (error) {
      expect(error).toBeInstanceOf(PlatformError);
      expect((error as PlatformError).code).toBe('auth.token_expired');
      expect((error as PlatformError).statusCode).toBe(401);
    }
  });
});

describe('tenant password compatibility', () => {
  const password = 'Fresh@2026Pass';

  it('verifies newly registered tenant passwords with Auth Service scrypt', () => {
    const passwordHash = hashTenantPassword(password);

    expect(passwordHash).toMatch(/^scrypt\$[a-f0-9]{32}\$[a-f0-9]{128}$/);
    expect(verifyPassword(password, passwordHash)).toBe(true);
    expect(verifyPassword('incorrect-password', passwordHash)).toBe(false);
  });

  it('verifies only the correct password for a legacy tenant hash', () => {
    const passwordHash = createHash('sha256').update(`nexoraa-tenant-v1${password}`).digest('hex');

    expect(verifyLegacyTenantPassword(password, passwordHash)).toBe(true);
    expect(verifyLegacyTenantPassword('incorrect-password', passwordHash)).toBe(false);
  });
});
