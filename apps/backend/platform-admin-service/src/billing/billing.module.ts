import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { SubscriptionModule } from '../subscription/subscription.module';
import {
  BillingAttemptMongoose,
  BillingAttemptMongooseSchema,
} from './billing-attempt.mongoose.schema';
import { MongoBillingAttemptRepository } from './billing-attempt.mongo.repository';
import { BillingController } from './billing.controller';
import { BillingService } from './billing.service';
import { BillingWebhookService } from './billing-webhook.service';
import { BILLING_ATTEMPT_REPOSITORY, BILLING_CHARGE_GATEWAY } from './billing.types';
import { RazorpayClientFactory } from './razorpay-client.factory';
import { RazorpayOrderService } from './razorpay-order.service';

/**
 * Grace-period-expiry -> PAST_DUE transition (PAYMENT_GRACE_PERIOD_DAYS,
 * billing.config.ts) is deliberately NOT implemented here. A payment.failed
 * webhook only records history in this phase (see BillingWebhookService);
 * nothing currently reads that history to decide a status transition later.
 * Recommendation: this belongs in its own follow-up (a scheduled job, likely
 * alongside whatever cron/scheduler infrastructure the repo ends up using —
 * none exists yet in this service), not bundled into Phase 3 or silently
 * folded into Phase 6's guard-wiring work.
 */
@Module({
  imports: [
    JwtModule.register({}),
    SubscriptionModule,
    MongooseModule.forFeature([
      { name: BillingAttemptMongoose.name, schema: BillingAttemptMongooseSchema },
    ]),
  ],
  controllers: [BillingController],
  providers: [
    PlatformRoleGuard,
    BillingService,
    BillingWebhookService,
    RazorpayClientFactory,
    RazorpayOrderService,
    MongoBillingAttemptRepository,
    { provide: BILLING_ATTEMPT_REPOSITORY, useExisting: MongoBillingAttemptRepository },
    { provide: BILLING_CHARGE_GATEWAY, useExisting: RazorpayOrderService },
  ],
  exports: [BillingService],
})
export class BillingModule {}
