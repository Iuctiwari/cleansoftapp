import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';

import { AuditModule } from '../audit/audit.module';
import { PlatformModule } from '../platform/platform.module';
import { AuthController } from './auth.controller';
import { AuthenticationContextMiddleware } from './auth.middleware';
import { InMemoryAuthRepository } from './auth.repository';
import { AuthService } from './auth.service';
import { AUTH_REPOSITORY } from './auth.types';

@Module({
  imports: [AuditModule, PlatformModule],
  controllers: [AuthController],
  providers: [
    AuthService,
    AuthenticationContextMiddleware,
    InMemoryAuthRepository,
    {
      provide: AUTH_REPOSITORY,
      useExisting: InMemoryAuthRepository,
    },
  ],
  exports: [AuthService, AuthenticationContextMiddleware],
})
export class AuthModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(AuthenticationContextMiddleware).forRoutes('*');
  }
}
