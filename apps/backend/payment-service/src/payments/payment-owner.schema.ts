import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, HydratedDocument } from 'mongoose';

// ─── Tenant owner (read-only projection) ────────────────────────────────────
//
// Payment Service does not own user/role data — tenant-service does, in the
// `tenantOwners` collection (see tenant-service's TenantOwnerMongoose). This
// mirrors branch-service's ManagerCandidateMongoose and order-service's own
// OrderOwnerLookupService: a read-only projection against that same shared
// collection, used only to resolve the tenant Owner's userId so they can be
// notified alongside whichever recipient the existing notification logic
// already targets. Never written to from here.
export type TenantOwnerDocument = HydratedDocument<TenantOwnerMongoose>;

@Schema({ collection: 'tenantOwners', timestamps: false, versionKey: false })
export class TenantOwnerMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  userId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true })
  roleCode!: string;

  @Prop({ required: true, enum: ['active', 'disabled'] })
  status!: string;
}

export const TenantOwnerMongooseSchema = SchemaFactory.createForClass(TenantOwnerMongoose);
