import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';

import { AdminAuthController } from './admin-auth.controller';
import { AdminAuthService } from './admin-auth.service';
import { AdminUserMongoose, AdminUserMongooseSchema } from './admin-user.mongoose.schema';
import { MongoAdminUserRepository } from './admin-user.mongo.repository';
import { ADMIN_USER_REPOSITORY } from './admin-auth.types';
import { PlatformRoleGuard } from './platform-role.guard';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    // Secrets are always supplied per-call (see AdminAuthService/PlatformRoleGuard)
    // so that access vs. refresh tokens never share a secret; JwtModule is
    // registered without a default secret to make that explicit.
    JwtModule.register({}),
    MongooseModule.forFeature([{ name: AdminUserMongoose.name, schema: AdminUserMongooseSchema }]),
  ],
  controllers: [AdminAuthController],
  providers: [
    AdminAuthService,
    PlatformRoleGuard,
    MongoAdminUserRepository,
    { provide: ADMIN_USER_REPOSITORY, useExisting: MongoAdminUserRepository },
  ],
  exports: [PlatformRoleGuard],
})
export class AdminAuthModule {}
