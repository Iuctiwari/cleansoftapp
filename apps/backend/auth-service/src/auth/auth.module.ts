import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';
import { AuditModule } from '../audit/audit.module';
import { EmailModule } from '../email/email.module';
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
  TenantStaffAuthMongoose,
  TenantStaffAuthMongooseSchema,
  UserBranchAssignmentMongoose,
  UserBranchAssignmentMongooseSchema,
} from './auth.mongoose.schema';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    AuditModule,
    PlatformModule,
    EmailModule,
    MongooseModule.forFeature([
      { name: AuthSessionMongoose.name, schema: AuthSessionMongooseSchema },
      { name: AuthLoginTrackerMongoose.name, schema: AuthLoginTrackerMongooseSchema },
      { name: PasswordResetMongoose.name, schema: PasswordResetMongooseSchema },
      { name: AuthNotificationIntentMongoose.name, schema: AuthNotificationIntentMongooseSchema },
      { name: PlatformUserMongoose.name, schema: PlatformUserMongooseSchema },
      { name: TenantOwnerAuthMongoose.name, schema: TenantOwnerAuthMongooseSchema },
      { name: TenantAuthMongoose.name, schema: TenantAuthMongooseSchema },
      { name: BranchAuthMongoose.name, schema: BranchAuthMongooseSchema },
      { name: TenantStaffAuthMongoose.name, schema: TenantStaffAuthMongooseSchema },
      { name: UserBranchAssignmentMongoose.name, schema: UserBranchAssignmentMongooseSchema },
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
  exports: [AuthenticationContextMiddleware, MongoAuthRepository],
})
export class AuthModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(AuthenticationContextMiddleware).forRoutes('*');
  }
}
