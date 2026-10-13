import { Prop, SchemaFactory } from '@nestjs/mongoose';
import { BaseSchema, DatabaseSchema } from '@nexoraa/database';
import { HydratedDocument, Schema as MongooseSchema, Types } from 'mongoose';
import { StaffAvailability, UserRole, UserStatus } from './user.types';

export type UserDocument = HydratedDocument<UserMongoose>;

@DatabaseSchema({ collection: 'users' })
export class UserMongoose extends BaseSchema {
  @Prop({ required: true, type: String })
  name!: string;

  @Prop({ type: String, sparse: true })
  email?: string;

  @Prop({ type: String, sparse: true })
  mobileNumber?: string;

  @Prop({ type: String })
  department?: string;

  /** Unique username within this tenant. Used for employee login. */
  @Prop({ required: true, type: String })
  loginId!: string;

  @Prop({ required: true, type: String, enum: ['Owner', 'Branch Manager', 'Staff', 'Cashier'] })
  role!: UserRole;

  @Prop({ type: [{ type: MongooseSchema.Types.ObjectId }] })
  branchIds!: Types.ObjectId[];

  @Prop({
    required: true,
    type: String,
    enum: ['Active', 'Suspended', 'Pending', 'Expired'],
    default: 'Pending',
  })
  status!: UserStatus;

  @Prop({
    required: true,
    type: String,
    enum: ['Available', 'Busy', 'On Break', 'Offline'],
    default: 'Available',
  })
  availability!: StaffAvailability;

  /**
   * Modules the owner switched on for this person (Staff role only). Unset = the
   * role's default access.
   */
  @Prop({ type: [String], default: undefined })
  customPermissions?: string[];

  @Prop({ type: Date })
  invitedAt?: Date;

  @Prop({ type: Date })
  lastLoginAt?: Date;
}

export const UserMongooseSchema = SchemaFactory.createForClass(UserMongoose);

// Ensure index on tenantId and email/mobile for fast lookups
UserMongooseSchema.index(
  { tenantId: 1, email: 1 },
  { unique: true, partialFilterExpression: { email: { $exists: true, $type: 'string' } } },
);
UserMongooseSchema.index(
  { tenantId: 1, mobileNumber: 1 },
  { unique: true, partialFilterExpression: { mobileNumber: { $exists: true, $type: 'string' } } },
);
UserMongooseSchema.index({ tenantId: 1, status: 1 });
// loginId must be unique within a tenant
UserMongooseSchema.index({ tenantId: 1, loginId: 1 }, { unique: true });
