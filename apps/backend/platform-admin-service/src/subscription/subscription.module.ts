import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import {
  SubscriptionHistoryMongoose,
  SubscriptionHistoryMongooseSchema,
} from './subscription-history.mongoose.schema';
import { MongoSubscriptionHistoryRepository } from './subscription-history.mongo.repository';
import { SubscriptionPlanController } from './subscription-plan.controller';
import {
  SubscriptionPlanMongoose,
  SubscriptionPlanMongooseSchema,
} from './subscription-plan.mongoose.schema';
import { SubscriptionPlanService } from './subscription-plan.service';
import {
  SUBSCRIPTION_HISTORY_REPOSITORY,
  TENANT_SUBSCRIPTION_REPOSITORY,
} from './subscription.types';
import { TenantSubscriptionController } from './tenant-subscription.controller';
import { MongoTenantSubscriptionRepository } from './tenant-subscription.mongo.repository';
import {
  TenantSubscriptionMongoose,
  TenantSubscriptionMongooseSchema,
} from './tenant-subscription.mongoose.schema';
import { TenantSubscriptionService } from './tenant-subscription.service';

@Module({
  imports: [
    // See BusinessTypeModule for why JwtModule must also be imported here:
    // PlatformRoleGuard's own dependencies are resolved via THIS module's
    // injector when attached via @UseGuards(), not AdminAuthModule's.
    JwtModule.register({}),
    MongooseModule.forFeature([
      { name: SubscriptionPlanMongoose.name, schema: SubscriptionPlanMongooseSchema },
      { name: TenantSubscriptionMongoose.name, schema: TenantSubscriptionMongooseSchema },
      { name: SubscriptionHistoryMongoose.name, schema: SubscriptionHistoryMongooseSchema },
    ]),
  ],
  controllers: [SubscriptionPlanController, TenantSubscriptionController],
  providers: [
    PlatformRoleGuard,
    SubscriptionPlanService,
    TenantSubscriptionService,
    MongoTenantSubscriptionRepository,
    MongoSubscriptionHistoryRepository,
    { provide: TENANT_SUBSCRIPTION_REPOSITORY, useExisting: MongoTenantSubscriptionRepository },
    { provide: SUBSCRIPTION_HISTORY_REPOSITORY, useExisting: MongoSubscriptionHistoryRepository },
  ],
  exports: [
    TENANT_SUBSCRIPTION_REPOSITORY,
    SUBSCRIPTION_HISTORY_REPOSITORY,
    SubscriptionPlanService,
    TenantSubscriptionService,
  ],
})
export class SubscriptionModule {}
