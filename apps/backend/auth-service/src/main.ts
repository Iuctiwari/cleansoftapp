import 'reflect-metadata';

import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';

import { AppModule } from './app.module';

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

  // Set up Redis microservice
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.REDIS,
    options: {
      host: configService.get('REDIS_HOST', 'redis'),
      port: configService.get<number>('REDIS_PORT', 6379),
      password: configService.get<string>('REDIS_PASSWORD'),
    },
  });

  const port = resolvePort(configService);
  const serviceName = configService.getOrThrow<string>('SERVICE_NAME');

  app.enableCors();
  app.enableShutdownHooks();

  // Start microservices and HTTP server
  await app.startAllMicroservices();
  await app.listen(port, HOST);

  logger.log(`${serviceName} listening on http://${HOST}:${port}`);
  logger.log(`${serviceName} microservice connected to Redis`);
}

void bootstrap();
