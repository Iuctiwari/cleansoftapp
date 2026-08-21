import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, HydratedDocument } from 'mongoose';

import type { TenantBusinessType } from './tenant.types';

// ─── Tenant ────────────────────────────────────────────────────────────────

export type TenantDocument = HydratedDocument<TenantMongoose>;

@Schema({ collection: 'tenants', timestamps: false, versionKey: false })
export class TenantMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  tenantId!: string;

  @Prop({ required: true, unique: true, index: true })
  slug!: string;

  @Prop({ required: true })
  businessName!: string;

  @Prop({
    required: true,
    enum: [
      'laundry',
      'dry_cleaning',
      'tailoring',
      'shoe_cleaning',
      'appliance_repair',
      'mobile_repair',
      'vehicle_wash',
      'salon',
      'general',
      'custom',
    ],
  })
  businessType!: string;

  @Prop({ required: true })
  ownerName!: string;

  @Prop({ required: true, unique: true, index: true })
  ownerEmail!: string;

  @Prop({ required: true, unique: true, index: true })
  ownerPhone!: string;

  @Prop({ required: true })
  ownerUserId!: string;

  @Prop({ required: true, default: true })
  taxEnabled!: boolean;

  @Prop({ required: true, default: 0 })
  defaultTaxPct!: number;

  @Prop({ required: true })
  subscriptionPlanId!: string;

  @Prop({
    required: true,
    enum: ['PendingVerification', 'Active', 'Suspended', 'Cancelled'],
    index: true,
  })
  status!: string;

  @Prop({ required: true })
  createdAt!: string;

  @Prop({ required: true })
  updatedAt!: string;
}

export const TenantMongooseSchema = SchemaFactory.createForClass(TenantMongoose);

// ─── Tenant Owner ───────────────────────────────────────────────────────────

export type TenantOwnerDocument = HydratedDocument<TenantOwnerMongoose>;

@Schema({ collection: 'tenantOwners', timestamps: false, versionKey: false })
export class TenantOwnerMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  userId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true })
  slug!: string;

  @Prop({ required: true })
  tenantName!: string;

  @Prop({ required: true })
  displayName!: string;

  @Prop({ required: true, unique: true, index: true })
  email!: string;

  @Prop({ required: true })
  mobileNumber!: string;

  @Prop({ required: true })
  passwordHash!: string;

  @Prop({ required: true })
  roleCode!: string;

  @Prop({ type: [String], required: true, default: [] })
  permissions!: string[];

  @Prop({ required: true, enum: ['active', 'disabled'] })
  status!: string;

  @Prop({ required: true, default: 1 })
  accessVersion!: number;

  @Prop({ required: true })
  createdAt!: string;
}

export const TenantOwnerMongooseSchema = SchemaFactory.createForClass(TenantOwnerMongoose);

// ─── Branch ─────────────────────────────────────────────────────────────────

export type BranchDocument = HydratedDocument<BranchMongoose>;

@Schema({ collection: 'branches', timestamps: false, versionKey: false })
export class BranchMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  branchId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true })
  branchName!: string;

  // Branch code — matches branch-service's BranchMongoose (same shared
  // `branches` collection). Optional at the schema level for branches
  // created before this field existed; enforced unique per tenant via the
  // sparse compound index below whenever present.
  @Prop({ trim: true, uppercase: true })
  code?: string;

  @Prop({ default: '' })
  streetAddress!: string;

  @Prop({ default: '' })
  city!: string;

  @Prop({ default: '' })
  state!: string;

  @Prop({ default: '' })
  country!: string;

  @Prop({ default: '' })
  postalCode!: string;

  @Prop({ required: true })
  phone!: string;

  @Prop({ required: true })
  email!: string;

  @Prop({ required: true, default: false })
  isHeadOffice!: boolean;

  @Prop({ required: true, enum: ['active', 'inactive', 'closed'], index: true })
  status!: string;

  @Prop({ required: true })
  createdAt!: string;

  @Prop({ required: true })
  updatedAt!: string;
}

export const BranchMongooseSchema = SchemaFactory.createForClass(BranchMongoose);
BranchMongooseSchema.index(
  { tenantId: 1, code: 1 },
  { unique: true, sparse: true, name: 'tenant_branch_code_unique' },
);

// ─── Tenant Service ──────────────────────────────────────────────────────────

export type TenantServiceDocument = HydratedDocument<TenantServiceMongoose>;

@Schema({ collection: 'tenantServices', timestamps: false, versionKey: false })
export class TenantServiceMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  tenantServiceId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({
    required: true,
    enum: [
      'laundry',
      'dry_cleaning',
      'tailoring',
      'shoe_cleaning',
      'appliance_repair',
      'mobile_repair',
      'vehicle_wash',
      'salon',
      'general',
      'custom',
    ],
  })
  serviceType!: TenantBusinessType;

  @Prop({ required: true, default: true })
  isEnabled!: boolean;

  @Prop({ required: true })
  createdAt!: string;
}

export const TenantServiceMongooseSchema = SchemaFactory.createForClass(TenantServiceMongoose);
TenantServiceMongooseSchema.index({ tenantId: 1, serviceType: 1 }, { unique: true });
