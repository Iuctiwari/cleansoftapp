import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { PlatformModule } from './platform/platform.module';
import { SchedulerModule } from './scheduler/scheduler.module';

function getNumericEnvironmentValue(
  configuration: Record<string, unknown>,
  key: string,
  fallback: number,
): number {
  const raw = configuration[key];
  const value = raw === undefined ? fallback : Number(raw);
  if (!Number.isInteger(value) || value <= 0) {
    throw new Error(`Environment variable ${key} must be a positive integer`);
  }

  return value;
}

function validateEnvironment(configuration: Record<string, unknown>): Record<string, unknown> {
  const requiredVariables = [
    'APP_NAME',
    'NODE_ENV',
    'HOST',
    'PORT',
    'API_PREFIX',
    'API_VERSION',
  ] as const;

  for (const variable of requiredVariables) {
    const value = configuration[variable];
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new Error(`Environment variable ${variable} is required`);
    }
  }

  const port = Number(configuration.PORT);
  if (!Number.isInteger(port) || port < 1 || port > 65_535) {
    throw new Error('Environment variable PORT must be a valid TCP port');
  }

  const nodeEnvironment = String(configuration.NODE_ENV);
  if (!['development', 'test', 'production'].includes(nodeEnvironment)) {
    throw new Error('Environment variable NODE_ENV must be development, test, or production');
  }

  const apiVersion = String(configuration.API_VERSION);
  if (!/^v?\d+$/.test(apiVersion)) {
    throw new Error('Environment variable API_VERSION must use a numeric URI version such as v1');
  }

  const accessTokenSecret =
    String(configuration.AUTH_ACCESS_TOKEN_SECRET ?? '').trim() || 'dev-access-token-secret';
  const refreshTokenSecret =
    String(configuration.AUTH_REFRESH_TOKEN_SECRET ?? '').trim() || 'dev-refresh-token-secret';

  return {
    ...configuration,
    API_PREFIX: String(configuration.API_PREFIX).replace(/^\/+|\/+$/g, ''),
    API_VERSION: apiVersion,
    PORT: port,
    AUTH_ACCESS_TOKEN_SECRET: accessTokenSecret,
    AUTH_REFRESH_TOKEN_SECRET: refreshTokenSecret,
    AUTH_ACCESS_TOKEN_TTL_SECONDS: getNumericEnvironmentValue(
      configuration,
      'AUTH_ACCESS_TOKEN_TTL_SECONDS',
      900,
    ),
    AUTH_REFRESH_TOKEN_TTL_SECONDS: getNumericEnvironmentValue(
      configuration,
      'AUTH_REFRESH_TOKEN_TTL_SECONDS',
      604800,
    ),
    AUTH_LOGIN_MAX_ATTEMPTS: getNumericEnvironmentValue(
      configuration,
      'AUTH_LOGIN_MAX_ATTEMPTS',
      5,
    ),
    AUTH_LOCKOUT_SECONDS: getNumericEnvironmentValue(configuration, 'AUTH_LOCKOUT_SECONDS', 900),
    AUTH_OTP_TTL_SECONDS: getNumericEnvironmentValue(configuration, 'AUTH_OTP_TTL_SECONDS', 600),
    AUTH_OTP_MAX_ATTEMPTS: getNumericEnvironmentValue(
      configuration,
      'AUTH_OTP_MAX_ATTEMPTS',
      5,
    ),
    AUTH_MAX_ACTIVE_SESSIONS: getNumericEnvironmentValue(
      configuration,
      'AUTH_MAX_ACTIVE_SESSIONS',
      3,
    ),
    AUTH_ALLOW_MULTI_DEVICE: String(configuration.AUTH_ALLOW_MULTI_DEVICE ?? 'true'),
  };
}

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      expandVariables: true,
      envFilePath: '.env',
      isGlobal: true,
      validate: validateEnvironment,
    }),
    PlatformModule,
    AuditModule,
    SchedulerModule,
    AuthModule,
  ],
})
export class AppModule {}
