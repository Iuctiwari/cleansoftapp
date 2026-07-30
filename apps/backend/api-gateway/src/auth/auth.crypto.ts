import { createHmac, randomBytes, randomUUID, scryptSync, timingSafeEqual } from 'node:crypto';

import { PlatformError } from '../platform/platform.errors';
import type {
  AuthAccessTokenClaims,
  AuthRefreshTokenClaims,
  SignedTokenEnvelope,
} from './auth.types';

interface JwtHeader {
  readonly alg: 'HS256';
  readonly typ: 'JWT';
}

function base64UrlEncode(value: string): string {
  return Buffer.from(value, 'utf8').toString('base64url');
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

export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(password, salt, 64).toString('hex');
  return `scrypt$${salt}$${hash}`;
}

export function verifyPassword(password: string, storedHash: string): boolean {
  const parts = storedHash.split('$');
  if (parts.length !== 3 || parts[0] !== 'scrypt') {
    return false;
  }

  const [, salt, expectedHash] = parts;
  const actualHash = scryptSync(password, salt, 64).toString('hex');
  return secureEqual(actualHash, expectedHash);
}

export function hashOpaqueSecret(secret: string, signingSecret: string): string {
  return createHmac('sha256', signingSecret).update(secret).digest('hex');
}

export function generateOtp(): string {
  const value = randomBytes(4).readUInt32BE(0) % 1_000_000;
  return value.toString().padStart(6, '0');
}

export function maskDestination(value: string): string {
  const trimmed = value.trim();
  if (trimmed.includes('@')) {
    const [localPart, domain] = trimmed.split('@');
    const visible = localPart.slice(0, 1);
    return `${visible}${'*'.repeat(Math.max(localPart.length - 1, 1))}@${domain}`;
  }

  if (trimmed.length <= 4) {
    return `${'*'.repeat(Math.max(trimmed.length - 1, 0))}${trimmed.slice(-1)}`;
  }

  return `${'*'.repeat(trimmed.length - 4)}${trimmed.slice(-4)}`;
}

export function signToken<TClaims>(
  tokenKind: 'access' | 'refresh',
  subject: string,
  claims: TClaims,
  options: {
    readonly issuer: string;
    readonly audience: string;
    readonly secret: string;
    readonly expiresInSeconds: number;
    readonly now?: Date;
  },
): {
  readonly token: string;
  readonly envelope: SignedTokenEnvelope<TClaims>;
} {
  const issuedAt = Math.floor((options.now ?? new Date()).getTime() / 1000);
  const envelope: SignedTokenEnvelope<TClaims> = {
    issuer: options.issuer,
    audience: options.audience,
    subject,
    tokenKind,
    issuedAt,
    expiresAt: issuedAt + options.expiresInSeconds,
    claims,
  };
  const header: JwtHeader = { alg: 'HS256', typ: 'JWT' };
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(envelope));
  const signature = createHmac('sha256', options.secret)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64url');

  return {
    token: `${encodedHeader}.${encodedPayload}.${signature}`,
    envelope,
  };
}

export function verifyToken<TClaims>(
  token: string,
  secret: string,
  expectedKind: 'access' | 'refresh',
  now: Date = new Date(),
): SignedTokenEnvelope<TClaims> {
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
  let payload: SignedTokenEnvelope<TClaims>;
  try {
    header = JSON.parse(base64UrlDecode(encodedHeader)) as JwtHeader;
    payload = JSON.parse(base64UrlDecode(encodedPayload)) as SignedTokenEnvelope<TClaims>;
  } catch {
    throw new PlatformError({
      code: 'auth.token_invalid',
      category: 'unauthenticated',
      messageKey: 'errors.auth.token_invalid',
    });
  }

  if (header.alg !== 'HS256' || header.typ !== 'JWT' || payload.tokenKind !== expectedKind) {
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

  return payload;
}

export function createAccessTokenId(): string {
  return randomUUID();
}

export function createRefreshFamilyId(): string {
  return randomUUID();
}

export function isAccessClaims(
  claims: AuthAccessTokenClaims | AuthRefreshTokenClaims,
): claims is AuthAccessTokenClaims {
  return claims.tokenKind === 'access';
}
