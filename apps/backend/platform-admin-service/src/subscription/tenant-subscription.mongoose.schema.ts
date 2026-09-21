import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';

import { BillingCycle, SubscriptionPlanKey, TenantSubscriptionStatus } from './subscription.types';

/**
 * This is what finally resolves Tenant.subscriptionPlanId (currently a dangling
 * placeholder in tenant-service — see tenant.service.ts). Keyed by tenantId
 * (tenant-service's own string identifier), read-only reference — this schema
 * does not modify or write to the Tenant document itself.
 */
@DatabaseSchema({ collection: 'platformTenantSubscriptions' })
export class TenantSubscriptionMongoose {
  @Prop({ required: true, trim: true, type: String, unique: true })
  tenantId!: string;

  @Prop({ enum: SubscriptionPlanKey, required: true, type: String })
  planKey!: SubscriptionPlanKey;

  @Prop({
    default: TenantSubscriptionStatus.TRIALING,
    enum: TenantSubscriptionStatus,
    required: true,
    type: String,
  })
  status!: TenantSubscriptionStatus;

  @Prop({ required: true, type: Date })
  startDate!: Date;

  @Prop({ type: Date })
  endDate?: Date;

  @Prop({ type: Date })
  trialEndsAt?: Date;

  @Prop({ min: 0, type: Number })
  branchLimit?: number;

  @Prop({ min: 0, type: Number })
  staffLimit?: number;

  @Prop({ min: 0, type: Number })
  monthlyOrderLimit?: number;

  @Prop({ enum: BillingCycle, required: true, type: String })
  billingCycle!: BillingCycle;

  @Prop({ default: false, required: true, type: Boolean })
  autoRenew!: boolean;

  @Prop({ maxlength: 1000, trim: true, type: String })
  notes?: string;

  @Prop({ type: String })
  updatedByAdminUserId?: string;
}

export const TenantSubscriptionMongooseSchema = SchemaFactory.createForClass(
  TenantSubscriptionMongoose,
);
TenantSubscriptionMongooseSchema.index(
  { tenantId: 1 },
  { name: 'platform_tenant_subscriptions_tenant_unique', unique: true },
);
