import { randomBytes, scryptSync } from 'node:crypto';

/**
 * Hashes a password using the format consumed by Auth Service.
 */
export function hashPassword(password: string): string {
  const salt = randomBytes(16).toString('hex');
  const hash = scryptSync(password, salt, 64).toString('hex');
  return `scrypt$${salt}$${hash}`;
}

/**
 * Generates a cryptographically random tenant ID (24 hex chars).
 */
export function generateTenantId(): string {
  return randomBytes(12).toString('hex');
}

/**
 * Generates a cryptographically random user ID (24 hex chars).
 */
export function generateUserId(): string {
  return randomBytes(12).toString('hex');
}

/**
 * Converts a business name to a URL-safe slug.
 * e.g. "Ahmed Laundry & Cleaners" -> "ahmed-laundry-cleaners"
 */
export function slugify(name: string): string {
  return name
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 48);
}
