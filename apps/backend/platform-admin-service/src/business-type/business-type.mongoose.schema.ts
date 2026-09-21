import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';

import { TenantBusinessType } from './business-type.enum';

/**
 * Used once, at tenant onboarding, to seed a new shop's services/items/
 * statuses/terminology (CleanSoft spec's Business-Type Management section).
 * All optional/defaulted — existing business types created before this field
 * existed just have empty defaults until an admin fills them in.
 */
export class BusinessTypeTerminologyMongoose {
  @Prop({ default: 'Customer', maxlength: 60, trim: true, type: String })
  customerLabel!: string;

  @Prop({ default: 'Order', maxlength: 60, trim: true, type: String })
  orderLabel!: string;

  @Prop({ default: 'Item', maxlength: 60, trim: true, type: String })
  itemLabel!: string;

  @Prop({ default: 'Delivery', maxlength: 60, trim: true, type: String })
  deliveryLabel!: string;
}

/**
 * Platform-level configuration, not tenant data — does not extend BaseSchema
 * (no tenantId applies). See admin-user.mongoose.schema.ts for the same rationale.
 */
@DatabaseSchema({ collection: 'platformBusinessTypes' })
export class BusinessTypeMongoose {
  @Prop({ enum: TenantBusinessType, required: true, type: String, unique: true })
  value!: TenantBusinessType;

  @Prop({ maxlength: 120, required: true, trim: true, type: String })
  label!: string;

  @Prop({ maxlength: 500, trim: true, type: String })
  description?: string;

  @Prop({ default: true, required: true, type: Boolean })
  isActive!: boolean;

  @Prop({ default: () => ({}), type: BusinessTypeTerminologyMongoose })
  defaultTerminology!: BusinessTypeTerminologyMongoose;

  @Prop({ default: [], type: [String] })
  defaultOrderStatuses!: string[];

  @Prop({ default: [], type: [String] })
  defaultServices!: string[];

  @Prop({ default: [], type: [String] })
  defaultItemCategories!: string[];

  @Prop({ default: [], type: [String] })
  defaultExpenseCategories!: string[];
}

export const BusinessTypeMongooseSchema = SchemaFactory.createForClass(BusinessTypeMongoose);
BusinessTypeMongooseSchema.index(
  { value: 1 },
  { name: 'platform_business_types_value_unique', unique: true },
);
