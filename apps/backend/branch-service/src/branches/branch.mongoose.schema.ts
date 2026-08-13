import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, HydratedDocument } from 'mongoose';

// ─── Branch ─────────────────────────────────────────────────────────────────
//
// This is the SAME `branches` collection already written to by tenant-service
// (on tenant registration, to create the head-office branch) and read by
// auth-service (to resolve tenant branch/login context). Field names, types,
// and the `timestamps: false, versionKey: false` shape are preserved exactly
// so existing documents and existing services remain compatible. Only the
// fields genuinely missing for NEX-136 are added: `code`, `openingTime`,
// `closingTime`, `managerId`.
//
// IDs and timestamps stay string-typed (not ObjectId / Date) to match the
// documents auth-service and tenant-service already write — using
// @nexoraa/database's BaseSchema here would silently change these types and
// break the shared collection.

export type BranchDocument = HydratedDocument<BranchMongoose>;

@Schema({ collection: 'branches', timestamps: false, versionKey: false })
export class BranchMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  branchId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true })
  branchName!: string;

  // Branch code — genuinely new for NEX-136. Optional at the schema level
  // (existing head-office branches were created without one) but enforced
  // unique per tenant via the sparse compound index below whenever present.
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

  // New for NEX-136 — 24-hour "HH:mm" strings.
  @Prop() openingTime?: string;
  @Prop() closingTime?: string;

  // New for NEX-136 — non-authoritative reference to a tenant user (see
  // branch.manager.ts). Never dereferenced into a user-record mutation.
  @Prop({ index: true })
  managerId?: string;

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

// ─── Manager candidate (read-only mirror of auth-service's tenant users) ────
//
// Branch Management does not own or manage users — User Management does
// (out of scope for NEX-136, and not yet implemented as a service). Until a
// dedicated Users API exists, tenant user accounts are recorded in the
// `tenantOwners` collection, which auth-service and tenant-service already
// treat as the canonical tenant-identity store (see auth-service's
// TenantOwnerAuthMongoose / tenant-service's TenantOwnerMongoose — this
// mirrors that exact pattern: a read-only projection against another
// service's collection, never written to from here).
export type ManagerCandidateDocument = HydratedDocument<ManagerCandidateMongoose>;

@Schema({ collection: 'tenantOwners', timestamps: false, versionKey: false })
export class ManagerCandidateMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  userId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true })
  displayName!: string;

  @Prop({ required: true })
  roleCode!: string;

  @Prop({ required: true, enum: ['active', 'disabled'] })
  status!: string;
}

export const ManagerCandidateMongooseSchema =
  SchemaFactory.createForClass(ManagerCandidateMongoose);
