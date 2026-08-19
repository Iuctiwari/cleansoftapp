import { Prop } from '@nestjs/mongoose';
import { BaseSchema, createBaseSchema, DatabaseSchema } from '@nexoraa/database';
import { HydratedDocument, Types } from 'mongoose';

export enum ExpensePaymentMethod {
  CASH = 'Cash',
  UPI = 'UPI',
  CARD = 'Card',
  BANK_TRANSFER = 'BankTransfer',
  OTHER = 'Other',
}

export enum ExpenseCategoryStatus {
  ACTIVE = 'Active',
  INACTIVE = 'Inactive',
}

export type ExpenseCategoryDocument = HydratedDocument<ExpenseCategoryMongoose>;
export type ExpenseDocument = HydratedDocument<ExpenseMongoose>;

@DatabaseSchema({ collection: 'expenseCategories' })
export class ExpenseCategoryMongoose extends BaseSchema {
  @Prop({ required: true, trim: true })
  categoryName!: string;

  @Prop({ trim: true })
  description?: string;

  @Prop({
    default: ExpenseCategoryStatus.ACTIVE,
    enum: ExpenseCategoryStatus,
    required: true,
    type: String,
  })
  status!: ExpenseCategoryStatus;
}

export const ExpenseCategoryMongooseSchema = createBaseSchema(ExpenseCategoryMongoose);

ExpenseCategoryMongooseSchema.index({ tenantId: 1 });
ExpenseCategoryMongooseSchema.index(
  { tenantId: 1, categoryName: 1, isDeleted: 1 },
  { unique: true },
);

@DatabaseSchema({ collection: 'expenses' })
export class ExpenseMongoose extends BaseSchema {
  @Prop({ immutable: true, required: true, type: String })
  branchId!: string;

  @Prop({
    ref: ExpenseCategoryMongoose.name,
    required: true,
    type: Types.ObjectId,
  })
  expenseCategoryId!: Types.ObjectId;

  @Prop({ min: 0.01, required: true, type: Number })
  amount!: number;

  @Prop({ enum: ExpensePaymentMethod, required: true, type: String })
  paymentMethod!: ExpensePaymentMethod;

  @Prop({ trim: true })
  vendor?: string;

  @Prop({ required: true, trim: true })
  description!: string;

  @Prop({ trim: true })
  attachment?: string;

  @Prop({ default: Date.now, required: true, type: Date })
  expenseDate!: Date;

  @Prop({ required: true, trim: true })
  recordedBy!: string;
}

export const ExpenseMongooseSchema = createBaseSchema(ExpenseMongoose);

ExpenseMongooseSchema.index({ tenantId: 1 });
ExpenseMongooseSchema.index({ tenantId: 1, branchId: 1 });
ExpenseMongooseSchema.index({ tenantId: 1, branchId: 1, isDeleted: 1, expenseDate: -1 });
ExpenseMongooseSchema.index({ tenantId: 1, expenseCategoryId: 1 });
