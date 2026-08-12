import 'reflect-metadata';

import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { setupSwagger } from '@nexoraa/swagger';

import { AppModule } from './app.module';
import { PlatformExceptionFilter } from './platform/platform.filter';
import {
  CorrelationIdInterceptor,
  ResponseEnvelopeInterceptor,
} from './platform/platform.interceptors';

const HOST = '0.0.0.0';

function resolvePort(configService: ConfigService): number {
  const port = Number(configService.getOrThrow<string>('PORT'));

  if (!Number.isInteger(port) || port < 1 || port > 65_535) {
    throw new Error('Environment variable PORT must be a valid TCP port');
  }

  return port;
}

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);
  const logger = new Logger('Bootstrap');
  const port = resolvePort(configService);
  const serviceName = configService.getOrThrow<string>('SERVICE_NAME');

  app.enableCors();
  app.enableShutdownHooks();
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  app.useGlobalPipes(
    new ValidationPipe({
      forbidNonWhitelisted: true,
      transform: true,
      whitelist: true,
    }),
  );
  app.useGlobalFilters(new PlatformExceptionFilter());
  app.useGlobalInterceptors(new CorrelationIdInterceptor(), new ResponseEnvelopeInterceptor());
  setupSwagger(app, { title: 'Nexoraa Branch Service API' });

  await app.listen(port, HOST);
  logger.log(`${serviceName} listening on http://${HOST}:${port}`);
}

void bootstrap();
