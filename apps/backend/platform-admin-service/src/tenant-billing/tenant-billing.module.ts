import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { BillingModule } from '../billing/billing.module';
import { SubscriptionModule } from '../subscription/subscription.module';
import { TenantAuthMiddleware } from '../tenant-config/tenant-auth.middleware';
import { TenantBillingController } from './tenant-billing.controller';
import { TenantBillingService } from './tenant-billing.service';

@Module({
  imports: [ConfigModule, SubscriptionModule, BillingModule],
  controllers: [TenantBillingController],
  providers: [TenantBillingService, TenantAuthMiddleware],
})
export class TenantBillingModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(TenantAuthMiddleware).forRoutes(TenantBillingController);
  }
}
