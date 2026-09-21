import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';

import { ModuleKey } from '../module-access/module-key.enum';
import { SubscriptionPlanKey } from './subscription.types';

@DatabaseSchema({ collection: 'platformSubscriptionPlans' })
export class SubscriptionPlanMongoose {
  @Prop({ enum: SubscriptionPlanKey, required: true, type: String, unique: true })
  planKey!: SubscriptionPlanKey;

  @Prop({ maxlength: 120, required: true, trim: true, type: String })
  displayName!: string;

  @Prop({ min: 0, required: true, type: Number })
  monthlyPriceInPaise!: number;

  @Prop({ min: 0, required: true, type: Number })
  annualPriceInPaise!: number;

  @Prop({ min: 0, required: true, type: Number })
  maxBranches!: number;

  @Prop({ min: 0, required: true, type: Number })
  maxStaff!: number;

  @Prop({ min: 0, required: true, type: Number })
  maxMonthlyOrders!: number;

  @Prop({ default: 0, min: 0, required: true, type: Number })
  trialDays!: number;

  @Prop({ default: [], enum: ModuleKey, type: [String] })
  includedModuleKeys!: ModuleKey[];

  @Prop({ default: true, required: true, type: Boolean })
  isActive!: boolean;
}

export const SubscriptionPlanMongooseSchema =
  SchemaFactory.createForClass(SubscriptionPlanMongoose);
SubscriptionPlanMongooseSchema.index(
  { planKey: 1 },
  { name: 'platform_subscription_plans_plan_key_unique', unique: true },
);
