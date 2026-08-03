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

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);
  const logger = new Logger('Bootstrap');

  app.enableCors();
  app.enableShutdownHooks();
  app.setGlobalPrefix(configService.getOrThrow<string>('API_PREFIX'));
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: configService.getOrThrow<string>('API_VERSION').replace(/^v/i, ''),
  });
  app.useGlobalPipes(
    new ValidationPipe({
      forbidNonWhitelisted: true,
      transform: true,
      whitelist: true,
    }),
  );
  app.useGlobalFilters(new PlatformExceptionFilter());
  app.useGlobalInterceptors(new CorrelationIdInterceptor(), new ResponseEnvelopeInterceptor());

  const appName = configService.getOrThrow<string>('APP_NAME');
  const environment = configService.getOrThrow<string>('NODE_ENV');
  const host = configService.getOrThrow<string>('HOST');
  const port = configService.getOrThrow<number>('PORT');

  setupSwagger(app, {
    documentPath: 'docs',
    title: `${appName} API Gateway`,
    useGlobalPrefix: true,
    version: configService.getOrThrow<string>('API_VERSION'),
  });

  logger.log(`Starting ${appName} in ${environment} mode`);
  await app.listen(port, host);
  logger.log(`API gateway listening on http://${host}:${port}`);
  logger.log(`Swagger UI → http://${host}:${port}/api/docs`);
}

void bootstrap();
