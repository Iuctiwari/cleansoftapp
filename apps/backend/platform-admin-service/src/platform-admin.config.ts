import { validateBillingEnvironment } from './billing/billing.config';

const REQUIRED_VARIABLES = [
  'NODE_ENV',
  'MONGODB_URI',
  'PLATFORM_ADMIN_ACCESS_TOKEN_SECRET',
  'PLATFORM_ADMIN_REFRESH_TOKEN_SECRET',
  'PLATFORM_ADMIN_ACCESS_TOKEN_TTL_SECONDS',
  'PLATFORM_ADMIN_REFRESH_TOKEN_TTL_SECONDS',
] as const;

const POSITIVE_INTEGER_VARIABLES = [
  'PLATFORM_ADMIN_ACCESS_TOKEN_TTL_SECONDS',
  'PLATFORM_ADMIN_REFRESH_TOKEN_TTL_SECONDS',
] as const;

/**
 * Deliberately independent of auth-service's env validation and secrets:
 * this service must never accept, verify, or fall back onto auth-service's
 * AUTH_ACCESS_TOKEN_SECRET / AUTH_REFRESH_TOKEN_SECRET.
 *
 * TENANT_SERVICE_BASE_URL and PLATFORM_ADMIN_INTERNAL_KEY are intentionally
 * NOT in REQUIRED_VARIABLES: they back TenantStatusGuard's cross-service
 * lookup (now an HTTP call to tenant-service's internal endpoint, not a
 * direct database read — see http-tenant-status.lookup.ts), which must fail
 * open (never crash boot, never block a tenant) when either is unset.
 */
export function validatePlatformAdminEnvironment(
  configuration: Record<string, unknown>,
): Record<string, unknown> {
  for (const variable of REQUIRED_VARIABLES) {
    const value = configuration[variable];
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new Error(`Environment variable ${variable} is required`);
    }
  }

  const nodeEnv = String(configuration.NODE_ENV);
  if (!['development', 'test', 'production'].includes(nodeEnv)) {
    throw new Error('Environment variable NODE_ENV must be development, test, or production');
  }

  for (const variable of POSITIVE_INTEGER_VARIABLES) {
    const value = Number(configuration[variable]);
    if (!Number.isInteger(value) || value <= 0) {
      throw new Error(`Environment variable ${variable} must be a positive integer`);
    }
  }

  const accessSecret = String(configuration.PLATFORM_ADMIN_ACCESS_TOKEN_SECRET);
  const refreshSecret = String(configuration.PLATFORM_ADMIN_REFRESH_TOKEN_SECRET);

  if (accessSecret.length < 32 || refreshSecret.length < 32) {
    throw new Error('Platform admin token secrets must each contain at least 32 characters');
  }
  if (accessSecret === refreshSecret) {
    throw new Error('Platform admin access-token and refresh-token secrets must be different');
  }
  if (
    [accessSecret, refreshSecret].some((secret) => /^(change[_-]?me|replace-with)/i.test(secret))
  ) {
    throw new Error('Platform admin token secrets must not use placeholder values');
  }

  return validateBillingEnvironment(configuration);
}
