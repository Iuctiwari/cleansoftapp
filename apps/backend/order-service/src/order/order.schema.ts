import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { DatabaseSchema } from '@nexoraa/database';
import { HydratedDocument, Schema as MongooseSchema, Types } from 'mongoose';

import { OrderPaymentStatus, OrderStatus } from './enums';

@Schema({ _id: true, timestamps: false, versionKey: false })
export class OrderItemMongoose {
  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  itemCategoryId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.Mixed })
  itemCategorySnapshot!: Record<string, unknown>;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  serviceId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.Mixed })
  serviceSnapshot!: Record<string, unknown>;

  @Prop({ min: 0.000_001, type: Number })
  quantity?: number;

  @Prop({ min: 0.000_001, type: Number })
  weight?: number;

  @Prop({ immutable: true, min: 0, required: true, type: Number })
  unitPrice!: number;

  @Prop({ default: 0, min: 0, required: true, type: Number })
  discount!: number;

  @Prop({ default: 0, min: 0, required: true, type: Number })
  tax!: number;

  @Prop({ min: 0, required: true, type: Number })
  lineTotal!: number;

  @Prop({ trim: true, type: String })
  processingStatus?: string;

  @Prop({ trim: true, type: String })
  notes?: string;
}

export const OrderItemMongooseSchema = SchemaFactory.createForClass(OrderItemMongoose);

OrderItemMongooseSchema.pre(
  'validate',
  function validateQuantityOrWeight(this: HydratedDocument<OrderItemMongoose>): void {
    if (this.quantity === undefined && this.weight === undefined) {
      this.invalidate('quantity', 'An order item requires quantity or weight');
    }
  },
);

@Schema({ _id: true, timestamps: false, versionKey: false })
export class OrderNoteMongoose {
  readonly _id!: Types.ObjectId;

  @Prop({ maxlength: 1000, required: true, trim: true, type: String })
  text!: string;

  @Prop({ default: 'General', enum: ['General', 'Damage'], required: true, type: String })
  kind!: string;

  @Prop({ type: MongooseSchema.Types.ObjectId })
  itemId?: Types.ObjectId;

  @Prop({ required: true, type: MongooseSchema.Types.ObjectId })
  authorId!: Types.ObjectId;

  @Prop({ required: true, trim: true, type: String })
  authorRole!: string;

  @Prop({ default: Date.now, required: true, type: Date })
  createdAt!: Date;
}

export const OrderNoteMongooseSchema = SchemaFactory.createForClass(OrderNoteMongoose);

export type OrderDocument = HydratedDocument<OrderMongoose>;

@DatabaseSchema({ collection: 'orders' })
export class OrderMongoose {
  readonly _id!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  tenantId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, trim: true, type: String })
  branchId!: string;

  @Prop({
    immutable: true,
    match: /^ORD-[A-Z0-9_-]+-[0-9]+$/,
    required: true,
    trim: true,
    type: String,
  })
  orderNumber!: string;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  customerId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.Mixed })
  customerSnapshot!: Record<string, unknown>;

  @Prop({ enum: OrderStatus, required: true, type: String })
  status!: OrderStatus;

  @Prop({
    default: OrderPaymentStatus.UNPAID,
    enum: OrderPaymentStatus,
    required: true,
    type: String,
  })
  paymentStatus!: OrderPaymentStatus;

  @Prop({
    required: true,
    type: [OrderItemMongooseSchema],
    validate: {
      message: 'An order requires at least one item',
      validator: (items: OrderItemMongoose[]): boolean => items.length > 0,
    },
  })
  items!: OrderItemMongoose[];

  @Prop({ min: 0, required: true, type: Number })
  subtotal!: number;

  @Prop({ default: 0, min: 0, required: true, type: Number })
  discount!: number;

  @Prop({ default: 0, max: 100, min: 0, required: true, type: Number })
  discountPercentage!: number;

  @Prop({ default: 0, min: 0, required: true, type: Number })
  tax!: number;

  @Prop({ min: 0, required: true, type: Number })
  grandTotal!: number;

  @Prop({ default: 0, min: 0, required: true, type: Number })
  paidAmount!: number;

  @Prop({ min: 0, required: true, type: Number })
  outstandingAmount!: number;

  @Prop({ default: [], select: false, type: [MongooseSchema.Types.ObjectId] })
  paymentProjectionIds!: Types.ObjectId[];

  @Prop({ type: Date })
  expectedDeliveryDate?: Date;

  @Prop({ type: Date })
  deliveryDate?: Date;

  @Prop({ type: MongooseSchema.Types.ObjectId })
  assignedTo?: Types.ObjectId;

  @Prop({ default: [], type: [OrderNoteMongooseSchema] })
  notes!: OrderNoteMongoose[];

  @Prop({ trim: true, type: String })
  cancelReason?: string;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  createdBy!: Types.ObjectId;

  readonly createdAt!: Date;
  readonly updatedAt!: Date;
  readonly version!: number;
}

export const OrderMongooseSchema = SchemaFactory.createForClass(OrderMongoose);

OrderMongooseSchema.index(
  { tenantId: 1, branchId: 1, orderNumber: 1 },
  { name: 'orders_tenant_branch_number_unique', unique: true },
);
OrderMongooseSchema.index({ tenantId: 1, branchId: 1, status: 1, createdAt: -1 });
OrderMongooseSchema.index({ tenantId: 1, customerId: 1, createdAt: -1 });
OrderMongooseSchema.index({ tenantId: 1, branchId: 1, paymentStatus: 1, createdAt: -1 });
OrderMongooseSchema.index({ tenantId: 1, branchId: 1, assignedTo: 1, status: 1 });
OrderMongooseSchema.index({ tenantId: 1, branchId: 1, expectedDeliveryDate: 1, status: 1 });
OrderMongooseSchema.index({ tenantId: 1, branchId: 1, 'items.serviceId': 1, createdAt: -1 });

export type CounterDocument = HydratedDocument<CounterMongoose>;

@DatabaseSchema({ collection: 'counters' })
export class CounterMongoose {
  readonly _id!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  tenantId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, trim: true, type: String })
  branchId!: string;

  @Prop({ immutable: true, required: true, trim: true, type: String })
  type!: string;

  @Prop({
    default: 0,
    min: 0,
    required: true,
    type: Number,
    validate: {
      message: 'Counter sequence must be a safe integer',
      validator: Number.isSafeInteger,
    },
  })
  sequence!: number;

  readonly createdAt!: Date;
  readonly updatedAt!: Date;
  readonly version!: number;
}

export const CounterMongooseSchema = SchemaFactory.createForClass(CounterMongoose);

CounterMongooseSchema.index(
  { tenantId: 1, branchId: 1, type: 1 },
  { name: 'counters_tenant_branch_type_unique', unique: true },
);

export type StatusHistoryDocument = HydratedDocument<StatusHistoryMongoose>;

@Schema({ collection: 'statusHistory', timestamps: false, versionKey: false })
export class StatusHistoryMongoose {
  readonly _id!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  tenantId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, trim: true, type: String })
  branchId!: string;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  orderId!: Types.ObjectId;

  @Prop({ enum: OrderStatus, immutable: true, required: true, type: String })
  previousStatus!: OrderStatus;

  @Prop({ enum: OrderStatus, immutable: true, required: true, type: String })
  newStatus!: OrderStatus;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  changedBy!: Types.ObjectId;

  @Prop({ immutable: true, trim: true, type: String })
  note?: string;

  @Prop({ default: Date.now, immutable: true, required: true, type: Date })
  timestamp!: Date;
}

export const StatusHistoryMongooseSchema = SchemaFactory.createForClass(StatusHistoryMongoose);

StatusHistoryMongooseSchema.index({ tenantId: 1, orderId: 1, timestamp: 1 });
StatusHistoryMongooseSchema.index({ tenantId: 1, branchId: 1, timestamp: -1 });

@Schema({ _id: false, timestamps: false, versionKey: false })
export class DeclineRequestMongoose {
  @Prop({ maxlength: 500, required: true, trim: true, type: String })
  reason!: string;

  @Prop({ enum: ['Pending', 'Approved', 'Denied'], required: true, type: String })
  status!: string;

  @Prop({ required: true, type: MongooseSchema.Types.ObjectId })
  requestedBy!: Types.ObjectId;

  @Prop({ required: true, type: Date })
  requestedAt!: Date;

  @Prop({ type: MongooseSchema.Types.ObjectId })
  resolvedBy?: Types.ObjectId;

  @Prop({ type: Date })
  resolvedAt?: Date;

  @Prop({ maxlength: 500, trim: true, type: String })
  responseNote?: string;
}

export const DeclineRequestMongooseSchema = SchemaFactory.createForClass(DeclineRequestMongoose);

export type AssignmentDocument = HydratedDocument<AssignmentMongoose>;

@DatabaseSchema({ collection: 'assignments' })
export class AssignmentMongoose {
  readonly _id!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  tenantId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, trim: true, type: String })
  branchId!: string;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  orderId!: Types.ObjectId;

  @Prop({ required: true, type: MongooseSchema.Types.ObjectId })
  assignedTo!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  assignedBy!: Types.ObjectId;

  @Prop({ type: Date })
  dueDate?: Date;

  @Prop({ trim: true, type: String })
  note?: string;

  @Prop({ required: true, trim: true, type: String })
  status!: string;

  @Prop({ type: DeclineRequestMongooseSchema })
  declineRequest?: DeclineRequestMongoose;

  readonly createdAt!: Date;
  readonly updatedAt!: Date;
  readonly version!: number;
}

export const AssignmentMongooseSchema = SchemaFactory.createForClass(AssignmentMongoose);

AssignmentMongooseSchema.index(
  { tenantId: 1, branchId: 1, orderId: 1 },
  { name: 'assignments_tenant_branch_order_unique', unique: true },
);
AssignmentMongooseSchema.index({ tenantId: 1, branchId: 1, assignedTo: 1, status: 1, dueDate: 1 });
AssignmentMongooseSchema.index(
  { tenantId: 1, branchId: 1, 'declineRequest.status': 1 },
  { partialFilterExpression: { 'declineRequest.status': 'Pending' } },
);
