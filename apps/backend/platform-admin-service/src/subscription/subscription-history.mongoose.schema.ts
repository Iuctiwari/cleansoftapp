import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Schema as MongooseSchema } from 'mongoose';

import { SubscriptionHistoryAction } from './subscription.types';

/**
 * Append-only audit log — deliberately plain @Schema (not @DatabaseSchema):
 * an immutable record has no meaningful updatedAt, so this only carries the
 * explicit `timestamp` field the append-only contract actually needs.
 */
@Schema({ collection: 'platformSubscriptionHistory' })
export class SubscriptionHistoryMongoose {
  @Prop({ immutable: true, required: true, trim: true, type: String })
  tenantId!: string;

  @Prop({ enum: SubscriptionHistoryAction, immutable: true, required: true, type: String })
  action!: SubscriptionHistoryAction;

  @Prop({ immutable: true, type: MongooseSchema.Types.Mixed })
  previousValue?: Record<string, unknown>;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.Mixed })
  newValue!: Record<string, unknown>;

  @Prop({ immutable: true, required: true, type: String })
  actorAdminUserId!: string;

  @Prop({ immutable: true, maxlength: 1000, trim: true, type: String })
  reason?: string;

  @Prop({ immutable: true, trim: true, type: String })
  razorpayEventId?: string;

  @Prop({ default: () => new Date(), immutable: true, required: true, type: Date })
  timestamp!: Date;
}

export const SubscriptionHistoryMongooseSchema = SchemaFactory.createForClass(
  SubscriptionHistoryMongoose,
);
SubscriptionHistoryMongooseSchema.index({ tenantId: 1, timestamp: -1 });
// Partial index: only enforces uniqueness when razorpayEventId is present, so
// the many history entries with no razorpayEventId (plan/status/extend
// actions) never collide with each other under this constraint.
SubscriptionHistoryMongooseSchema.index(
  { razorpayEventId: 1 },
  {
    name: 'platform_subscription_history_razorpay_event_unique',
    partialFilterExpression: { razorpayEventId: { $exists: true } },
    unique: true,
  },
);
