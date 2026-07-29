import 'reflect-metadata';

import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';

import { AppModule } from './app.module';

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create(AppModule);
  const configService = app.get(ConfigService);
  const logger = new Logger('Bootstrap');

  app.enableCors();
  app.enableShutdownHooks();
  app.setGlobalPrefix(configService.getOrThrow<string>('API_PREFIX'));
  app.enableVersioning({
    type: VersioningType.URI,
    defaultVersion: configService
      .getOrThrow<string>('API_VERSION')
      .replace(/^v/i, ''),
  });
  app.useGlobalPipes(
    new ValidationPipe({
      forbidNonWhitelisted: true,
      transform: true,
      whitelist: true,
    }),
  );

  const appName = configService.getOrThrow<string>('APP_NAME');
  const environment = configService.getOrThrow<string>('NODE_ENV');
  const host = configService.getOrThrow<string>('HOST');
  const port = configService.getOrThrow<number>('PORT');

  logger.log(`Starting ${appName} in ${environment} mode`);
  await app.listen(port, host);
  logger.log(`API gateway listening on http://${host}:${port}`);
}

void bootstrap();
