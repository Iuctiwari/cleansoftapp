import { Global, MiddlewareConsumer, Module, type NestModule, RequestMethod } from '@nestjs/common';
import { LoggerModule as PinoLoggerModule } from 'nestjs-pino';

import { CorrelationIdMiddleware } from './correlation-id.middleware';
import { createLoggerModuleParams } from './logger.config';
import { LOGGER_SERVICE_TOKEN } from './logger.constants';
import { LOGGER_PROVIDERS } from './logger.providers';
import { LoggerService } from './logger.service';

@Global()
@Module({
  imports: [PinoLoggerModule.forRoot(createLoggerModuleParams())],
  providers: [...LOGGER_PROVIDERS],
  exports: [LOGGER_SERVICE_TOKEN, LoggerService, PinoLoggerModule],
})
export class LoggerModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CorrelationIdMiddleware).forRoutes({ path: '*', method: RequestMethod.ALL });
  }
}
