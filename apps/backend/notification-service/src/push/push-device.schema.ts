import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import type { HydratedDocument } from 'mongoose';

export type PushDeviceDocument = HydratedDocument<PushDeviceMongoose>;

/**
 * A phone that can receive pushes. One row per Firebase token: when someone
 * else signs in on the same phone, the token moves to them (upsert by token).
 */
@Schema({ collection: 'pushDevices', versionKey: false })
export class PushDeviceMongoose {
  @Prop({ required: true, unique: true })
  token!: string;

  /** shop = a shop user (owner/staff); consumer = a marketplace customer. */
  @Prop({ required: true, enum: ['shop', 'consumer'] })
  kind!: 'shop' | 'consumer';

  /** The shop user id or the consumer id. */
  @Prop({ required: true, index: true })
  accountId!: string;

  // Shop users only ────────────────────────────────────────────────────────
  @Prop() tenantId?: string;
  /** The branch the user is working in on this phone. */
  @Prop() branchId?: string;
  @Prop() roleCode?: string;
  /** Owner, or has orders:read — i.e. should hear about new online requests. */
  @Prop() seesOrders?: boolean;
  @Prop() isOwner?: boolean;

  @Prop({ default: 'android' })
  platform!: string;

  @Prop() appVersion?: string;

  @Prop({ required: true })
  createdAt!: Date;

  @Prop({ required: true })
  lastSeenAt!: Date;
}

export const PushDeviceMongooseSchema = SchemaFactory.createForClass(PushDeviceMongoose);
PushDeviceMongooseSchema.index({ kind: 1, tenantId: 1, branchId: 1 });
PushDeviceMongooseSchema.index({ kind: 1, tenantId: 1, isOwner: 1 });
