import { DatabaseSchema } from '@nexoraa/database';
import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Schema as MongooseSchema, Types } from 'mongoose';

export type PaymentDocument = HydratedDocument<PaymentMongoose>;

@DatabaseSchema({ collection: 'payments' })
export class PaymentMongoose {
  readonly _id!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  tenantId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, trim: true })
  branchId!: string;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  orderId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  customerId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, trim: true })
  paymentNumber!: string;

  @Prop({ enum: ['Advance'], immutable: true, required: true })
  paymentType!: 'Advance';

  @Prop({ enum: ['Cash', 'Card', 'UPI'], immutable: true, required: true })
  method!: 'Cash' | 'Card' | 'UPI';

  @Prop({ immutable: true, min: 1, required: true, type: Number })
  amountMinor!: number;

  @Prop({ default: 'INR', immutable: true, match: /^[A-Z]{3}$/, required: true })
  currency!: string;

  @Prop({ enum: ['Pending', 'Successful', 'Failed'], required: true })
  status!: 'Pending' | 'Successful' | 'Failed';

  @Prop({ immutable: true, required: true, trim: true })
  idempotencyKey!: string;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  recordedBy!: Types.ObjectId;

  readonly createdAt!: Date;
  readonly updatedAt!: Date;
}

export const PaymentMongooseSchema = SchemaFactory.createForClass(PaymentMongoose);
PaymentMongooseSchema.index(
  { tenantId: 1, idempotencyKey: 1, paymentType: 1 },
  { name: 'payments_tenant_idempotency_operation_unique', unique: true },
);
PaymentMongooseSchema.index(
  { tenantId: 1, paymentNumber: 1 },
  { name: 'payments_tenant_number_unique', unique: true },
);
PaymentMongooseSchema.index({ tenantId: 1, branchId: 1, orderId: 1, status: 1 });
