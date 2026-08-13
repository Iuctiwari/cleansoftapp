import { createHmac, timingSafeEqual } from 'node:crypto';

import { PlatformError } from './platform.errors';

/**
 * Verifies access tokens issued by auth-service. This mirrors the HS256
 * envelope format defined in auth-service/src/auth/auth.crypto.ts — branch-service
 * has no session store of its own, so it can only verify the token signature
 * and expiry locally; it cannot detect a token revoked via logout before expiry
 * (see auth-service's session-revocation check, which requires the auth_sessions
 * collection that branch-service does not have access to).
 */
export interface AccessTokenClaims {
  readonly tokenKind: 'access';
  readonly sessionId: string;
  readonly userId: string;
  readonly kind: 'platform' | 'tenant';
  readonly roleCode: string;
  readonly permissions: readonly string[];
  readonly accessVersion: number;
  readonly tenantId?: string;
  readonly branchId?: string;
}

interface JwtHeader {
  readonly alg: 'HS256';
  readonly typ: 'JWT';
}

interface SignedTokenEnvelope {
  readonly tokenKind: 'access' | 'refresh';
  readonly expiresAt: number;
  readonly claims: AccessTokenClaims;
}

function base64UrlDecode(value: string): string {
  return Buffer.from(value, 'base64url').toString('utf8');
}

function secureEqual(left: string, right: string): boolean {
  const leftBuffer = Buffer.from(left, 'utf8');
  const rightBuffer = Buffer.from(right, 'utf8');
  if (leftBuffer.length !== rightBuffer.length) {
    return false;
  }

  return timingSafeEqual(leftBuffer, rightBuffer);
}

export function verifyAccessToken(
  token: string,
  secret: string,
  now: Date = new Date(),
): AccessTokenClaims {
  const parts = token.split('.');
  if (parts.length !== 3) {
    throw new PlatformError({
      code: 'auth.token_invalid',
      category: 'unauthenticated',
      messageKey: 'errors.auth.token_invalid',
    });
  }

  const [encodedHeader, encodedPayload, signature] = parts;
  const expectedSignature = createHmac('sha256', secret)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64url');
  if (!secureEqual(signature, expectedSignature)) {
    throw new PlatformError({
      code: 'auth.token_invalid',
      category: 'unauthenticated',
      messageKey: 'errors.auth.token_invalid',
    });
  }

  let header: JwtHeader;
  let payload: SignedTokenEnvelope;
  try {
    header = JSON.parse(base64UrlDecode(encodedHeader)) as JwtHeader;
    payload = JSON.parse(base64UrlDecode(encodedPayload)) as SignedTokenEnvelope;
  } catch {
    throw new PlatformError({
      code: 'auth.token_invalid',
      category: 'unauthenticated',
      messageKey: 'errors.auth.token_invalid',
    });
  }

  if (header.alg !== 'HS256' || header.typ !== 'JWT' || payload.tokenKind !== 'access') {
    throw new PlatformError({
      code: 'auth.token_invalid',
      category: 'unauthenticated',
      messageKey: 'errors.auth.token_invalid',
    });
  }

  const epochSeconds = Math.floor(now.getTime() / 1000);
  if (payload.expiresAt <= epochSeconds) {
    throw new PlatformError({
      code: 'auth.token_expired',
      category: 'unauthenticated',
      messageKey: 'errors.auth.token_expired',
    });
  }

  return payload.claims;
}
