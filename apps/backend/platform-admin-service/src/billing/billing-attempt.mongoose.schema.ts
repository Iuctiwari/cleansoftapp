import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';

import { BillingCycle, SubscriptionPlanKey } from '../subscription/subscription.types';
import { BillingAttemptStatus } from './billing.types';

/**
 * One document per create-order call — NOT a single field on
 * TenantSubscription. TenantSubscription is a single current-state document
 * (unique per tenantId); a scalar `razorpayOrderId` field on it could only
 * ever hold the most recent order, losing every earlier attempt and breaking
 * lookups for a late-arriving webhook about an older order. This collection
 * also gives the webhook handler a clean, indexed `razorpayOrderId -> tenant`
 * lookup, which a mutable field on TenantSubscription cannot.
 */
@DatabaseSchema({ collection: 'platformBillingAttempts' })
export class BillingAttemptMongoose {
  @Prop({ required: true, trim: true, type: String })
  tenantId!: string;

  @Prop({ required: true, trim: true, type: String, unique: true })
  razorpayOrderId!: string;

  @Prop({ trim: true, type: String })
  razorpayPaymentId?: string;

  @Prop({ min: 0, required: true, type: Number })
  amountInPaise!: number;

  @Prop({ default: 'INR', required: true, type: String })
  currency!: string;

  @Prop({ enum: BillingCycle, required: true, type: String })
  billingCycle!: BillingCycle;

  @Prop({ enum: SubscriptionPlanKey, required: true, type: String })
  planKeyAtCreation!: SubscriptionPlanKey;

  @Prop({
    default: BillingAttemptStatus.CREATED,
    enum: BillingAttemptStatus,
    required: true,
    type: String,
  })
  status!: BillingAttemptStatus;
}

export const BillingAttemptMongooseSchema = SchemaFactory.createForClass(BillingAttemptMongoose);
BillingAttemptMongooseSchema.index(
  { razorpayOrderId: 1 },
  { name: 'platform_billing_attempts_order_unique', unique: true },
);
BillingAttemptMongooseSchema.index({ tenantId: 1, createdAt: -1 });
