import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { ModuleAccessModule } from '../module-access/module-access.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { TenantStatusModule } from '../tenant-status/tenant-status.module';
import { EnforcementController } from './enforcement.controller';
import { EnforcementService } from './enforcement.service';
import { InternalServiceGuard } from './internal-service.guard';

@Module({
  imports: [ConfigModule, SubscriptionModule, ModuleAccessModule, TenantStatusModule],
  controllers: [EnforcementController],
  providers: [EnforcementService, InternalServiceGuard],
})
export class EnforcementModule {}
