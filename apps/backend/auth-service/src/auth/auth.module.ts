import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ClientsModule, Transport, ClientProvider } from '@nestjs/microservices';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';
import { PlatformModule } from '../platform/platform.module';
import { AuthController } from './auth.controller';
import { AuthenticationContextMiddleware } from './auth.middleware';
import { MongoAuthRepository } from './auth.mongo.repository';
import { AuthService } from './auth.service';
import { AUTH_REPOSITORY } from './auth.types';

import {
  AuthSessionMongoose,
  AuthSessionMongooseSchema,
  AuthLoginTrackerMongoose,
  AuthLoginTrackerMongooseSchema,
  PasswordResetMongoose,
  PasswordResetMongooseSchema,
  AuthNotificationIntentMongoose,
  AuthNotificationIntentMongooseSchema,
  PlatformUserMongoose,
  PlatformUserMongooseSchema,
  TenantOwnerAuthMongoose,
  TenantOwnerAuthMongooseSchema,
  TenantAuthMongoose,
  TenantAuthMongooseSchema,
  BranchAuthMongoose,
  BranchAuthMongooseSchema,
} from './auth.mongoose.schema';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    PlatformModule,
    MongooseModule.forFeature([
      { name: AuthSessionMongoose.name, schema: AuthSessionMongooseSchema },
      { name: AuthLoginTrackerMongoose.name, schema: AuthLoginTrackerMongooseSchema },
      { name: PasswordResetMongoose.name, schema: PasswordResetMongooseSchema },
      { name: AuthNotificationIntentMongoose.name, schema: AuthNotificationIntentMongooseSchema },
      { name: PlatformUserMongoose.name, schema: PlatformUserMongooseSchema },
      { name: TenantOwnerAuthMongoose.name, schema: TenantOwnerAuthMongooseSchema },
      { name: TenantAuthMongoose.name, schema: TenantAuthMongooseSchema },
      { name: BranchAuthMongoose.name, schema: BranchAuthMongooseSchema },
    ]),
    // Dummy audit client to prevent crashing until AuditService is a real microservice
    ClientsModule.registerAsync([
      {
        name: 'AUDIT_CLIENT',
        imports: [ConfigModule],
        useFactory: (configService: ConfigService): ClientProvider => ({
          transport: Transport.REDIS,
          options: {
            host: configService.get('REDIS_HOST', 'redis'),
            port: configService.get<number>('REDIS_PORT', 6379),
          },
        }),
        inject: [ConfigService],
      },
    ]),
  ],
  controllers: [AuthController],
  providers: [
    AuthService,
    MongoAuthRepository,
    {
      provide: AUTH_REPOSITORY,
      useExisting: MongoAuthRepository,
    },
    AuthenticationContextMiddleware,
  ],
  exports: [AuthenticationContextMiddleware],
})
export class AuthModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(AuthenticationContextMiddleware).forRoutes('*');
  }
}
