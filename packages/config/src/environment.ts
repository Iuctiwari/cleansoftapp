import type { ConfigModuleOptions } from '@nestjs/config';

export type EnvironmentProfile = 'gateway' | 'service';

export interface EnvironmentConfigOptions {
  envFilePath?: string | string[];
  profile: EnvironmentProfile;
}

const gatewayVariables = [
  'APP_NAME',
  'NODE_ENV',
  'HOST',
  'PORT',
  'API_PREFIX',
  'API_VERSION',
  'MONGODB_URI',
] as const;

const serviceVariables = [
  'NODE_ENV',
  'SERVICE_NAME',
  'SERVICE_HOST',
  'SERVICE_PORT',
  'MONGODB_URI',
  'REDIS_URL',
  'LOG_LEVEL',
] as const;

function requireVariables(
  configuration: Record<string, unknown>,
  variables: readonly string[],
): void {
  for (const variable of variables) {
    const value = configuration[variable];
    if (typeof value !== 'string' || value.trim().length === 0) {
      throw new Error(`Environment variable ${variable} is required`);
    }
  }
}

function validateNodeEnvironment(configuration: Record<string, unknown>): void {
  const nodeEnvironment = String(configuration.NODE_ENV);
  if (!['development', 'test', 'production'].includes(nodeEnvironment)) {
    throw new Error('Environment variable NODE_ENV must be development, test, or production');
  }
}

function parsePort(configuration: Record<string, unknown>, variable: string): number {
  const port = Number(configuration[variable]);
  if (!Number.isInteger(port) || port < 1 || port > 65_535) {
    throw new Error(`Environment variable ${variable} must be a valid TCP port`);
  }

  return port;
}

function validateUrlProtocol(value: unknown, variable: string, protocols: readonly string[]): void {
  let url: URL;

  try {
    url = new URL(String(value));
  } catch {
    throw new Error(`Environment variable ${variable} must be a valid URL`);
  }

  if (!protocols.includes(url.protocol)) {
    throw new Error(
      `Environment variable ${variable} must use ${protocols.join(' or ').replaceAll(':', '')}`,
    );
  }
}

export function validateGatewayEnvironment(
  configuration: Record<string, unknown>,
): Record<string, unknown> {
  requireVariables(configuration, gatewayVariables);
  validateNodeEnvironment(configuration);

  const port = parsePort(configuration, 'PORT');
  validateUrlProtocol(configuration.MONGODB_URI, 'MONGODB_URI', ['mongodb:', 'mongodb+srv:']);

  const apiVersion = String(configuration.API_VERSION);
  if (!/^v?\d+$/.test(apiVersion)) {
    throw new Error('Environment variable API_VERSION must use a numeric URI version such as v1');
  }

  return {
    ...configuration,
    API_PREFIX: String(configuration.API_PREFIX).replace(/^\/+|\/+$/g, ''),
    API_VERSION: apiVersion,
    PORT: port,
  };
}

export function validateServiceEnvironment(
  configuration: Record<string, unknown>,
): Record<string, unknown> {
  requireVariables(configuration, serviceVariables);
  validateNodeEnvironment(configuration);

  validateUrlProtocol(configuration.MONGODB_URI, 'MONGODB_URI', ['mongodb:', 'mongodb+srv:']);
  validateUrlProtocol(configuration.REDIS_URL, 'REDIS_URL', ['redis:', 'rediss:']);

  return {
    ...configuration,
    SERVICE_PORT: parsePort(configuration, 'SERVICE_PORT'),
  };
}

export function createEnvironmentConfig(options: EnvironmentConfigOptions): ConfigModuleOptions {
  return {
    cache: true,
    expandVariables: true,
    envFilePath: options.envFilePath ?? '.env',
    isGlobal: true,
    validate:
      options.profile === 'gateway' ? validateGatewayEnvironment : validateServiceEnvironment,
  };
}

export function createGatewayEnvironmentConfig(
  envFilePath?: string | string[],
): ConfigModuleOptions {
  return createEnvironmentConfig({ envFilePath, profile: 'gateway' });
}

export function createServiceEnvironmentConfig(
  envFilePath?: string | string[],
): ConfigModuleOptions {
  return createEnvironmentConfig({ envFilePath, profile: 'service' });
}
