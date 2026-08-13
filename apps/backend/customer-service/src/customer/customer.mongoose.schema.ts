import { Prop } from '@nestjs/mongoose';
import { BaseSchema, createBaseSchema, DatabaseSchema } from '@nexoraa/database';
import { HydratedDocument } from 'mongoose';

export enum CustomerType {
  REGULAR = 'Regular',
  WALK_IN = 'Walk-in',
  CORPORATE = 'Corporate',
  VIP = 'VIP',
}

export type CustomerDocument = HydratedDocument<CustomerMongoose>;

@DatabaseSchema({ collection: 'customers' })
export class CustomerMongoose extends BaseSchema {
  @Prop({ immutable: true, required: true, type: String })
  branchId!: string;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({
    required(this: CustomerMongoose): boolean {
      return this.customerType !== CustomerType.WALK_IN;
    },
    trim: true,
  })
  mobile?: string;

  @Prop({ lowercase: true, trim: true })
  email?: string;

  @Prop({ trim: true })
  address?: string;

  @Prop({ enum: CustomerType, required: true, type: String })
  customerType!: CustomerType;

  @Prop({ default: Date.now, required: true, type: Date })
  joiningDate!: Date;

  @Prop({ default: 0, min: 0, required: true, type: Number })
  totalOrders!: number;

  @Prop({ default: 0, min: 0, required: true, type: Number })
  totalSpent!: number;

  @Prop({ default: 0, required: true, type: Number })
  outstandingBalance!: number;

  @Prop({ default: null, type: Date })
  lastOrderDate!: Date | null;
}

export const CustomerMongooseSchema = createBaseSchema(CustomerMongoose);

CustomerMongooseSchema.index({ tenantId: 1 });
CustomerMongooseSchema.index({ tenantId: 1, name: 1 });
CustomerMongooseSchema.index({ tenantId: 1, mobile: 1 });
CustomerMongooseSchema.index({ tenantId: 1, branchId: 1 });
CustomerMongooseSchema.index({ tenantId: 1, branchId: 1, isDeleted: 1, name: 1 });
CustomerMongooseSchema.index({ tenantId: 1, branchId: 1, isDeleted: 1, mobile: 1 });
