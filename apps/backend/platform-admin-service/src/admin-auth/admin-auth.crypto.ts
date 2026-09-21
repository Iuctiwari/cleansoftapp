import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

/**
 * Self-contained password hashing for platform-admin-service. Intentionally not
 * imported from auth-service (services in this repo do not share source across
 * boundaries) — mirrors the scrypt shape auth-service uses for its own accounts,
 * but is a fully independent implementation with no shared code path or secret.
 */
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

  const actualBuffer = Buffer.from(actualHash, 'utf8');
  const expectedBuffer = Buffer.from(expectedHash, 'utf8');
  if (actualBuffer.length !== expectedBuffer.length) {
    return false;
  }

  return timingSafeEqual(actualBuffer, expectedBuffer);
}
