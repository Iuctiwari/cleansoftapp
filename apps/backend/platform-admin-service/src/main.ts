import 'reflect-metadata';

import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { setupSwagger } from '@nexoraa/swagger';

import { AppModule } from './app.module';

const HOST = '0.0.0.0';

function resolvePort(configService: ConfigService): number {
  const rawPort =
    configService.get<string>('PORT') ?? configService.get<string>('SERVICE_PORT') ?? '3015';
  const port = Number(rawPort);

  if (!Number.isInteger(port) || port < 1 || port > 65_535) {
    throw new Error('Environment variable PORT must be a valid TCP port');
  }

  return port;
}

async function bootstrap(): Promise<void> {
  // rawBody: true exposes request.rawBody (the exact bytes received) on every
  // request without changing normal JSON body parsing — needed so the
  // Razorpay webhook route can verify signatures against the exact bytes
  // Razorpay signed, not a re-serialized copy.
  const app = await NestFactory.create(AppModule, { rawBody: true });
  const configService = app.get(ConfigService);
  const logger = new Logger('Bootstrap');
  const port = resolvePort(configService);
  const serviceName = configService.get<string>('SERVICE_NAME', 'platform-admin-service');

  app.enableCors();
  app.enableShutdownHooks();
  app.setGlobalPrefix('api');
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  app.useGlobalPipes(
    new ValidationPipe({ forbidNonWhitelisted: true, transform: true, whitelist: true }),
  );
  setupSwagger(app, { title: 'Nexoraa Platform Admin API', useGlobalPrefix: true });

  await app.listen(port, HOST);
  logger.log(`${serviceName} listening on http://${HOST}:${port}`);
}

void bootstrap();
