import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, HydratedDocument, Schema as MongooseSchema } from 'mongoose';

// ─── Auth Session ──────────────────────────────────────────────────────────

export type AuthSessionDocument = HydratedDocument<AuthSessionMongoose>;

@Schema({ collection: 'auth_sessions', timestamps: false, versionKey: false })
export class AuthSessionMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  sessionId!: string;

  @Prop({ required: true, index: true })
  familyId!: string;

  @Prop({ required: true, index: true })
  userId!: string;

  @Prop({ required: true, enum: ['platform', 'tenant'] })
  kind!: string;

  @Prop({ required: true })
  roleCode!: string;

  @Prop({ type: [String], required: true, default: [] })
  permissions!: string[];

  @Prop({ required: true, default: 1 })
  accessVersion!: number;

  @Prop() tenantId?: string;
  @Prop() tenantSlug?: string;
  @Prop() tenantName?: string;
  @Prop() branchId?: string;
  @Prop() branchCode?: string;
  @Prop() branchName?: string;

  @Prop({ required: true })
  refreshTokenHash!: string;

  @Prop({ required: true })
  expiresAtUtc!: string;

  @Prop({ required: true })
  createdAtUtc!: string;

  @Prop({ required: true })
  lastActivityAtUtc!: string;

  @Prop() revokedAtUtc?: string;
  @Prop() revokedReason?: string;
  @Prop() reuseDetectedAtUtc?: string;
  @Prop() deviceId?: string;
  @Prop() deviceName?: string;
  @Prop() ipAddress?: string;
  @Prop() userAgent?: string;
}

export const AuthSessionMongooseSchema = SchemaFactory.createForClass(AuthSessionMongoose);

// ─── Auth Login Tracker ────────────────────────────────────────────────────

export type AuthLoginTrackerDocument = HydratedDocument<AuthLoginTrackerMongoose>;

@Schema({ collection: 'auth_login_trackers', timestamps: false, versionKey: false })
export class AuthLoginTrackerMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  trackerKey!: string;

  @Prop({ required: true, default: 0 })
  failedAttempts!: number;

  @Prop() lockedUntilUtc?: string;

  @Prop({ required: true })
  updatedAtUtc!: string;
}

export const AuthLoginTrackerMongooseSchema = SchemaFactory.createForClass(AuthLoginTrackerMongoose);

// ─── Password Reset ────────────────────────────────────────────────────────

export type PasswordResetDocument = HydratedDocument<PasswordResetMongoose>;

@Schema({ collection: 'auth_password_resets', timestamps: false, versionKey: false })
export class PasswordResetMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  resetId!: string;

  @Prop({ required: true, index: true })
  userId!: string;

  @Prop({ required: true, enum: ['platform', 'tenant'] })
  kind!: string;

  @Prop() tenantId?: string;
  @Prop() tenantSlug?: string;

  @Prop({ required: true })
  otpHash!: string;

  @Prop({ required: true })
  expiresAtUtc!: string;

  @Prop({ required: true, default: 0 })
  attempts!: number;

  @Prop({ required: true, default: false })
  consumed!: boolean;

  @Prop({ required: true })
  createdAtUtc!: string;

  @Prop({ required: true, enum: ['email', 'sms'] })
  deliveryChannel!: string;

  @Prop({ required: true })
  destinationMasked!: string;
}

export const PasswordResetMongooseSchema = SchemaFactory.createForClass(PasswordResetMongoose);

// ─── Auth Notification Intent ──────────────────────────────────────────────

export type AuthNotificationIntentDocument = HydratedDocument<AuthNotificationIntentMongoose>;

@Schema({ collection: 'auth_notifications', timestamps: false, versionKey: false })
export class AuthNotificationIntentMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  notificationId!: string;

  @Prop({ required: true, enum: ['email', 'sms'] })
  channel!: string;

  @Prop({ required: true })
  destinationMasked!: string;

  @Prop({ required: true })
  templateCode!: string;

  @Prop({ type: MongooseSchema.Types.Mixed, required: true })
  payload!: Record<string, string>;

  @Prop({ required: true })
  createdAtUtc!: string;
}

export const AuthNotificationIntentMongooseSchema = SchemaFactory.createForClass(AuthNotificationIntentMongoose);

// ─── Platform User ─────────────────────────────────────────────────────────

export type PlatformUserDocument = HydratedDocument<PlatformUserMongoose>;

@Schema({ collection: 'platformUsers', timestamps: false, versionKey: false })
export class PlatformUserMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  userId!: string;

  @Prop({ required: true, unique: true, index: true })
  email!: string;

  @Prop({ index: true })
  mobileNumber?: string;

  @Prop({ required: true })
  displayName!: string;

  @Prop({ required: true })
  passwordHash!: string;

  @Prop({ required: true })
  roleCode!: string;

  @Prop({ type: [String], required: true, default: [] })
  permissions!: string[];

  @Prop({ required: true, enum: ['active', 'disabled'], default: 'active' })
  status!: string;

  @Prop({ required: true, default: 1 })
  accessVersion!: number;

  @Prop({ required: true })
  passwordChangedAtUtc!: string;

  @Prop({ required: true })
  createdAtUtc!: string;
}

export const PlatformUserMongooseSchema = SchemaFactory.createForClass(PlatformUserMongoose);

// ─── Tenant Read Models (Mapped to tenant-service collections) ─────────────

export type TenantOwnerAuthDocument = HydratedDocument<TenantOwnerAuthMongoose>;

@Schema({ collection: 'tenantOwners', timestamps: false, versionKey: false })
export class TenantOwnerAuthMongoose extends Document {
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
}

export const TenantOwnerAuthMongooseSchema = SchemaFactory.createForClass(TenantOwnerAuthMongoose);

export type TenantAuthDocument = HydratedDocument<TenantAuthMongoose>;

@Schema({ collection: 'tenants', timestamps: false, versionKey: false })
export class TenantAuthMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  tenantId!: string;

  @Prop({ required: true, unique: true, index: true })
  slug!: string;

  @Prop({ required: true })
  status!: string;
}

export const TenantAuthMongooseSchema = SchemaFactory.createForClass(TenantAuthMongoose);

export type BranchAuthDocument = HydratedDocument<BranchAuthMongoose>;

@Schema({ collection: 'branches', timestamps: false, versionKey: false })
export class BranchAuthMongoose extends Document {
  @Prop({ required: true, unique: true, index: true })
  branchId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true })
  branchName!: string;

  @Prop({ required: true })
  isHeadOffice!: boolean;

  @Prop({ required: true })
  status!: string;
}

export const BranchAuthMongooseSchema = SchemaFactory.createForClass(BranchAuthMongoose);
