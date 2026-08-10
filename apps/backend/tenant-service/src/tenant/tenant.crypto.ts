import { createHash, randomBytes } from 'node:crypto';

/**
 * Hashes a password using SHA-256 with a fixed application salt.
 * NOTE: In production, replace with bcrypt or argon2 for proper adaptive hashing.
 */
export function hashPassword(password: string): string {
  const salt = 'nexoraa-tenant-v1';
  return createHash('sha256')
    .update(salt + password)
    .digest('hex');
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
