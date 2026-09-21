import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER } from '@nestjs/core';
import { GlobalExceptionFilter } from '@nexoraa/common';

import { AdminAuthModule } from './admin-auth/admin-auth.module';
import { AppController } from './app.controller';
import { AppHealth } from './app.service';
import { BillingModule } from './billing/billing.module';
import { BusinessTypeModule } from './business-type/business-type.module';
import { EnforcementModule } from './enforcement/enforcement.module';
import { ModuleAccessModule } from './module-access/module-access.module';
import { validatePlatformAdminEnvironment } from './platform-admin.config';
import { SubscriptionModule } from './subscription/subscription.module';
import { TenantBillingModule } from './tenant-billing/tenant-billing.module';
import { TenantConfigModule } from './tenant-config/tenant-config.module';
import { TenantDirectoryModule } from './tenant-directory/tenant-directory.module';
import { TenantResourceCountsModule } from './tenant-resource-counts/tenant-resource-counts.module';
import { TenantStatusModule } from './tenant-status/tenant-status.module';
import { ThemeModule } from './theme/theme.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      envFilePath: ['.env', '../../.env'],
      expandVariables: true,
      isGlobal: true,
      validate: validatePlatformAdminEnvironment,
    }),
    AdminAuthModule,
    BusinessTypeModule,
    ModuleAccessModule,
    SubscriptionModule,
    TenantStatusModule,
    BillingModule,
    ThemeModule,
    TenantConfigModule,
    TenantBillingModule,
    TenantDirectoryModule,
    EnforcementModule,
    TenantResourceCountsModule,
  ],
  controllers: [AppController],
  providers: [AppHealth, { provide: APP_FILTER, useClass: GlobalExceptionFilter }],
})
export class AppModule {}
