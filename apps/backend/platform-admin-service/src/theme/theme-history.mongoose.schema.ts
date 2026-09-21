import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Schema as MongooseSchema } from 'mongoose';

import { ThemeHistoryAction } from './theme.types';

/**
 * A dedicated collection rather than reusing SubscriptionHistory: theme edits
 * (branding) and subscription/billing events are different bounded contexts.
 * SubscriptionHistory's action enum and its consumers (TenantSubscription
 * flows) are billing-specific; folding THEME_UPDATED into that collection
 * would mean every billing audit query has to filter out unrelated branding
 * noise, and vice versa. The append-only shape is identical, so this is a
 * direct copy of that pattern (see subscription-history.mongoose.schema.ts)
 * — plain @Schema, not @DatabaseSchema, since an immutable log has no
 * meaningful updatedAt.
 */
@Schema({ collection: 'platformThemeHistory' })
export class ThemeHistoryMongoose {
  @Prop({ immutable: true, required: true, trim: true, type: String })
  tenantId!: string;

  @Prop({ enum: ThemeHistoryAction, immutable: true, required: true, type: String })
  action!: ThemeHistoryAction;

  @Prop({ immutable: true, type: MongooseSchema.Types.Mixed })
  previousValue?: Record<string, unknown>;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.Mixed })
  newValue!: Record<string, unknown>;

  @Prop({ immutable: true, required: true, type: String })
  actorAdminUserId!: string;

  @Prop({ default: () => new Date(), immutable: true, required: true, type: Date })
  timestamp!: Date;
}

export const ThemeHistoryMongooseSchema = SchemaFactory.createForClass(ThemeHistoryMongoose);
ThemeHistoryMongooseSchema.index({ tenantId: 1, timestamp: -1 });
