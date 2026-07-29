import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppService } from './app.service';

function validateEnvironment(
  configuration: Record<string, unknown>,
): Record<string, unknown> {
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
    throw new Error(
      'Environment variable NODE_ENV must be development, test, or production',
    );
  }

  const apiVersion = String(configuration.API_VERSION);
  if (!/^v?\d+$/.test(apiVersion)) {
    throw new Error(
      'Environment variable API_VERSION must use a numeric URI version such as v1',
    );
  }

  return {
    ...configuration,
    API_PREFIX: String(configuration.API_PREFIX).replace(/^\/+|\/+$/g, ''),
    API_VERSION: apiVersion,
    PORT: port,
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
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
