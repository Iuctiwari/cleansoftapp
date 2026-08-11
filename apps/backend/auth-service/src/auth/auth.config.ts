import { validateGatewayEnvironment } from '@nexoraa/config';

const requiredAuthVariables = [
  'AUTH_ACCESS_TOKEN_SECRET',
  'AUTH_REFRESH_TOKEN_SECRET',
  'AUTH_ACCESS_TOKEN_TTL_SECONDS',
  'AUTH_REFRESH_TOKEN_TTL_SECONDS',
  'AUTH_LOGIN_MAX_ATTEMPTS',
  'AUTH_LOCKOUT_SECONDS',
  'AUTH_OTP_TTL_SECONDS',
  'AUTH_OTP_MAX_ATTEMPTS',
  'AUTH_MAX_ACTIVE_SESSIONS',
  'AUTH_ALLOW_MULTI_DEVICE',
] as const;

const positiveIntegerVariables = [
  'AUTH_ACCESS_TOKEN_TTL_SECONDS',
  'AUTH_REFRESH_TOKEN_TTL_SECONDS',
  'AUTH_LOGIN_MAX_ATTEMPTS',
  'AUTH_LOCKOUT_SECONDS',
  'AUTH_OTP_TTL_SECONDS',
  'AUTH_OTP_MAX_ATTEMPTS',
  'AUTH_MAX_ACTIVE_SESSIONS',
] as const;

export function validateAuthEnvironment(
  configuration: Record<string, unknown>,
): Record<string, unknown> {
  const validated = validateGatewayEnvironment(configuration);

  for (const variable of requiredAuthVariables) {
    const value = validated[variable];
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new Error(`Environment variable ${variable} is required`);
    }
  }

  for (const variable of positiveIntegerVariables) {
    const value = Number(validated[variable]);
    if (!Number.isInteger(value) || value <= 0) {
      throw new Error(`Environment variable ${variable} must be a positive integer`);
    }
  }

  const accessSecret = String(validated.AUTH_ACCESS_TOKEN_SECRET);
  const refreshSecret = String(validated.AUTH_REFRESH_TOKEN_SECRET);
  if (accessSecret.length < 32 || refreshSecret.length < 32) {
    throw new Error('Authentication token secrets must each contain at least 32 characters');
  }
  if (accessSecret === refreshSecret) {
    throw new Error('Access-token and refresh-token secrets must be different');
  }
  if (
    [accessSecret, refreshSecret].some((secret) => /^(change[_-]?me|replace-with)/i.test(secret))
  ) {
    throw new Error('Authentication token secrets must not use placeholder values');
  }

  if (!['true', 'false'].includes(String(validated.AUTH_ALLOW_MULTI_DEVICE).toLowerCase())) {
    throw new Error('Environment variable AUTH_ALLOW_MULTI_DEVICE must be true or false');
  }

  return validated;
}
