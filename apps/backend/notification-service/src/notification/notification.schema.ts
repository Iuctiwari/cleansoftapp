import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';
import { HydratedDocument, Schema as MongooseSchema, Types } from 'mongoose';

import { NotificationType } from './notification.types';

export type NotificationDocument = HydratedDocument<NotificationMongoose>;

@DatabaseSchema({ collection: 'notifications' })
export class NotificationMongoose {
  readonly _id!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  tenantId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, trim: true, type: String })
  branchId!: string;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  recipientId!: Types.ObjectId;

  @Prop({ required: true, trim: true, type: String })
  title!: string;

  @Prop({ required: true, trim: true, type: String })
  message!: string;

  @Prop({ enum: NotificationType, immutable: true, required: true, type: String })
  type!: NotificationType;

  @Prop({ immutable: true, trim: true, type: String })
  entityType?: string;

  @Prop({ immutable: true, type: MongooseSchema.Types.ObjectId })
  entityId?: Types.ObjectId;

  @Prop({ immutable: true, type: MongooseSchema.Types.ObjectId })
  orderId?: Types.ObjectId;

  @Prop({ default: false, required: true, type: Boolean })
  isRead!: boolean;

  readonly createdAt!: Date;
  readonly updatedAt!: Date;
}

export const NotificationMongooseSchema = SchemaFactory.createForClass(NotificationMongoose);

NotificationMongooseSchema.index({
  tenantId: 1,
  branchId: 1,
  recipientId: 1,
  isRead: 1,
  createdAt: -1,
});
NotificationMongooseSchema.index({ tenantId: 1, branchId: 1, createdAt: -1 });
NotificationMongooseSchema.index({ orderId: 1 }, { sparse: true });
