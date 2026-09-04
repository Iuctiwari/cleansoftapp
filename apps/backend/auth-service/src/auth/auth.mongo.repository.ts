import { Injectable, OnModuleInit } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, FilterQuery } from 'mongoose';
import { effectivePermissions } from '@nexoraa/shared';
import { hashPassword } from './auth.crypto';
import { normalizeIdentifier } from './auth.normalization';

import type {
  AuthIdentityRecord,
  AuthLoginContext,
  AuthLoginTracker,
  AuthNotificationIntent,
  AuthRepository,
  AuthSessionRecord,
  PasswordResetRecord,
  StaffAuthRecord,
} from './auth.types';

import {
  AuthSessionDocument,
  AuthSessionMongoose,
  AuthLoginTrackerDocument,
  AuthLoginTrackerMongoose,
  PasswordResetDocument,
  PasswordResetMongoose,
  AuthNotificationIntentDocument,
  AuthNotificationIntentMongoose,
  PlatformUserDocument,
  PlatformUserMongoose,
  TenantOwnerAuthDocument,
  TenantOwnerAuthMongoose,
  TenantAuthDocument,
  TenantAuthMongoose,
  BranchAuthDocument,
  BranchAuthMongoose,
  TenantStaffAuthDocument,
  TenantStaffAuthMongoose,
  UserBranchAssignmentDocument,
  UserBranchAssignmentMongoose,
} from './auth.mongoose.schema';

@Injectable()
export class MongoAuthRepository implements AuthRepository, OnModuleInit {
  constructor(
    @InjectModel(AuthSessionMongoose.name)
    private readonly sessionModel: Model<AuthSessionDocument>,
    @InjectModel(AuthLoginTrackerMongoose.name)
    private readonly trackerModel: Model<AuthLoginTrackerDocument>,
    @InjectModel(PasswordResetMongoose.name)
    private readonly resetModel: Model<PasswordResetDocument>,
    @InjectModel(AuthNotificationIntentMongoose.name)
    private readonly notificationModel: Model<AuthNotificationIntentDocument>,
    @InjectModel(PlatformUserMongoose.name)
    private readonly platformUserModel: Model<PlatformUserDocument>,
    @InjectModel(TenantOwnerAuthMongoose.name)
    private readonly tenantOwnerModel: Model<TenantOwnerAuthDocument>,
    @InjectModel(TenantAuthMongoose.name) private readonly tenantModel: Model<TenantAuthDocument>,
    @InjectModel(BranchAuthMongoose.name) private readonly branchModel: Model<BranchAuthDocument>,
    @InjectModel(TenantStaffAuthMongoose.name)
    private readonly tenantStaffModel: Model<TenantStaffAuthDocument>,
    @InjectModel(UserBranchAssignmentMongoose.name)
    private readonly userBranchAssignmentModel: Model<UserBranchAssignmentDocument>,
  ) {}

  async onModuleInit(): Promise<void> {
    const adminCount = await this.platformUserModel.countDocuments().exec();
    if (adminCount === 0) {
      await this.platformUserModel.create({
        userId: 'platform-admin-1',
        email: 'platform.admin@nexoraa.local',
        mobileNumber: '9000000001',
        displayName: 'Platform Administrator',
        passwordHash: hashPassword('Platform#123'),
        roleCode: 'platform_admin',
        permissions: ['platform:read', 'platform:write', 'audit:read', 'jobs:manage'],
        status: 'active',
        accessVersion: 1,
        passwordChangedAtUtc: new Date().toISOString(),
        createdAtUtc: new Date().toISOString(),
      });
    }
  }

  async findIdentity(
    context: AuthLoginContext,
    identifier: string,
    tenantSlug?: string,
  ): Promise<AuthIdentityRecord | null> {
    const normalized = normalizeIdentifier(identifier);

    if (context === 'platform') {
      const user = await this.platformUserModel
        .findOne({
          $or: [{ email: normalized }, { mobileNumber: normalized }],
        })
        .lean()
        .exec();

      if (!user) return null;
      return {
        userId: user.userId,
        kind: 'platform',
        email: user.email,
        mobileNumber: user.mobileNumber,
        displayName: user.displayName,
        passwordHash: user.passwordHash,
        roleCode: user.roleCode,
        permissions: Object.freeze(user.permissions),
        status: user.status as AuthIdentityRecord['status'],
        accessVersion: user.accessVersion,
        branches: Object.freeze([]),
        passwordChangedAtUtc: user.passwordChangedAtUtc,
      };
    }

    if (context === 'tenant') {
      const tenant = tenantSlug
        ? await this.tenantModel.findOne({ slug: tenantSlug }).lean().exec()
        : null;
      const owner = await this.tenantOwnerModel
        .findOne({
          ...(tenant ? { tenantId: tenant.tenantId } : {}),
          $or: [{ email: normalized }, { mobileNumber: normalized }],
        })
        .lean()
        .exec();

      if (!owner) {
        // Owner not found — try staff lookup by loginId
        return this.findStaffIdentityByLoginId(normalized);
      }
      const resolvedTenant =
        tenant ?? (await this.tenantModel.findOne({ tenantId: owner.tenantId }).lean().exec());
      if (!resolvedTenant) return null;

      const branches = await this.branchModel
        .find({ tenantId: resolvedTenant.tenantId, status: 'active' })
        .lean()
        .exec();
      const mappedBranches = branches.map((b) => ({
        branchId: b.branchId,
        branchCode: b.branchName.replace(/\s+/g, '-').toLowerCase(), // Fallback since actual branchCode is missing in Mongoose model
        branchName: b.branchName,
      }));

      return {
        userId: owner.userId,
        kind: 'tenant',
        email: owner.email,
        mobileNumber: owner.mobileNumber,
        displayName: owner.displayName,
        passwordHash: owner.passwordHash,
        roleCode: owner.roleCode,
        permissions: effectivePermissions(owner.roleCode, owner.permissions),
        status: owner.status as AuthIdentityRecord['status'],
        accessVersion: owner.accessVersion,
        tenantId: resolvedTenant.tenantId,
        tenantSlug: resolvedTenant.slug,
        tenantName: owner.tenantName,
        tenantStatus: resolvedTenant.status === 'Active' ? 'active' : 'disabled',
        branches: Object.freeze(mappedBranches),
        defaultBranchId: mappedBranches.find(
          (b) => branches.find((ob) => ob.branchId === b.branchId)?.isHeadOffice,
        )?.branchId,
        passwordChangedAtUtc: new Date().toISOString(), // Fallback if missing
      };
    }

    return null;
  }

  /**
   * Look up a staff member by loginId within a tenant.
   * Called after owner lookup fails so staff can log in with their loginId.
   */
  private async findStaffIdentityByLoginId(loginId: string): Promise<AuthIdentityRecord | null> {
    const normalized = normalizeIdentifier(loginId);
    const filter: Record<string, unknown> = { loginId: normalized };
    // In a single-tenant or global login system, loginId (email) is unique enough.
    // If the mobile app sends a generic slug like "nexoraa-admin", filtering by it
    // will break login for staff members of other tenants.
    const staff = await this.tenantStaffModel.findOne(filter).lean().exec();
    if (!staff) return null;

    const resolvedTenant = await this.tenantModel
      .findOne({ tenantId: staff.tenantId })
      .lean()
      .exec();
    if (!resolvedTenant) return null;

    const assignment = await this.userBranchAssignmentModel.findById(staff.userId).lean().exec();
    const assignedBranchIds = staff.branchIds?.length
      ? staff.branchIds
      : (assignment?.branchIds ?? []).map(String);
    const branches = await this.branchModel
      .find({ tenantId: staff.tenantId, branchId: { $in: assignedBranchIds } })
      .lean()
      .exec();
    const mappedBranches = branches.map((b) => ({
      branchId: b.branchId,
      branchCode: b.branchName.replace(/\s+/g, '-').toLowerCase(),
      branchName: b.branchName,
    }));

    return {
      userId: staff.userId,
      kind: 'tenant',
      // Use loginId as the email field so existing auth flow works for identifier lookup
      email: staff.loginId,
      displayName: staff.displayName,
      passwordHash: staff.passwordHash,
      roleCode: staff.roleCode,
      permissions: effectivePermissions(staff.roleCode, staff.permissions),
      status: staff.status as AuthIdentityRecord['status'],
      accessVersion: staff.accessVersion,
      tenantId: staff.tenantId,
      tenantSlug: staff.tenantSlug,
      tenantName: staff.tenantName,
      tenantStatus: resolvedTenant.status === 'Active' ? 'active' : 'disabled',
      branches: Object.freeze(mappedBranches),
      defaultBranchId: mappedBranches.find(
        (b) => branches.find((ob) => ob.branchId === b.branchId)?.isHeadOffice,
      )?.branchId,
      passwordChangedAtUtc: staff.createdAtUtc,
      loginId: staff.loginId,
    };
  }

  async findIdentityByUserId(userId: string): Promise<AuthIdentityRecord | null> {
    const platform = await this.platformUserModel.findOne({ userId }).lean().exec();
    if (platform) {
      return this.findIdentity('platform', platform.email);
    }

    const tenantOwner = await this.tenantOwnerModel.findOne({ userId }).lean().exec();
    if (tenantOwner) {
      return this.findIdentity('tenant', tenantOwner.email, tenantOwner.slug);
    }

    // Check staff identities
    const staff = await this.tenantStaffModel.findOne({ userId }).lean().exec();
    if (staff) {
      return this.findStaffIdentityByLoginId(staff.loginId);
    }

    return null;
  }

  async resetLoginTracker(trackerKey: string): Promise<void> {
    await this.trackerModel.deleteOne({ trackerKey }).exec();
  }

  async getLoginTracker(trackerKey: string): Promise<AuthLoginTracker | null> {
    const doc = await this.trackerModel.findOne({ trackerKey }).lean().exec();
    if (!doc) return null;
    return {
      trackerKey: doc.trackerKey,
      failedAttempts: doc.failedAttempts,
      lockedUntilUtc: doc.lockedUntilUtc,
      updatedAtUtc: doc.updatedAtUtc,
    };
  }

  async saveLoginTracker(tracker: AuthLoginTracker): Promise<AuthLoginTracker> {
    await this.trackerModel
      .updateOne({ trackerKey: tracker.trackerKey }, { $set: tracker }, { upsert: true })
      .exec();
    return tracker;
  }

  async replaceIdentity(identity: AuthIdentityRecord): Promise<AuthIdentityRecord> {
    if (identity.kind === 'platform') {
      await this.platformUserModel
        .updateOne(
          { userId: identity.userId },
          {
            $set: {
              passwordHash: identity.passwordHash,
              accessVersion: identity.accessVersion,
              passwordChangedAtUtc: identity.passwordChangedAtUtc,
            },
          },
        )
        .exec();
    } else if (identity.kind === 'tenant') {
      await this.tenantOwnerModel
        .updateOne(
          { userId: identity.userId },
          {
            $set: {
              passwordHash: identity.passwordHash,
              accessVersion: identity.accessVersion,
            },
          },
        )
        .exec();
    } else if (identity.kind === 'tenant_staff') {
      await this.tenantStaffModel
        .updateOne(
          { userId: identity.userId },
          {
            $set: {
              passwordHash: identity.passwordHash,
              accessVersion: identity.accessVersion,
            },
          },
        )
        .exec();
    }
    return identity;
  }

  async createSession(session: AuthSessionRecord): Promise<AuthSessionRecord> {
    await this.sessionModel.create(session);
    return session;
  }

  async updateSession(session: AuthSessionRecord): Promise<AuthSessionRecord> {
    await this.sessionModel.updateOne({ sessionId: session.sessionId }, { $set: session }).exec();
    return session;
  }

  async findSessionById(sessionId: string): Promise<AuthSessionRecord | null> {
    const doc = await this.sessionModel.findOne({ sessionId }).lean().exec();
    if (!doc) return null;
    return doc as unknown as AuthSessionRecord;
  }

  async listActiveSessionsByUser(userId: string): Promise<readonly AuthSessionRecord[]> {
    const docs = await this.sessionModel
      .find({
        userId,
        revokedAtUtc: { $exists: false },
      })
      .sort({ createdAtUtc: 1 })
      .lean()
      .exec();
    return docs as unknown as AuthSessionRecord[];
  }

  async revokeSessionsByFamily(
    familyId: string,
    reason: string,
    revokedAtUtc: string,
  ): Promise<readonly AuthSessionRecord[]> {
    const sessionsToRevoke = await this.sessionModel
      .find({
        familyId,
        revokedAtUtc: { $exists: false },
      })
      .lean()
      .exec();

    await this.sessionModel
      .updateMany(
        { familyId, revokedAtUtc: { $exists: false } },
        {
          $set: {
            revokedAtUtc,
            revokedReason: reason,
            reuseDetectedAtUtc:
              reason === 'refresh_token_reuse_detected' ? revokedAtUtc : undefined,
          },
        },
      )
      .exec();

    return sessionsToRevoke.map((s) => ({
      ...s,
      revokedAtUtc,
      revokedReason: reason,
      reuseDetectedAtUtc:
        reason === 'refresh_token_reuse_detected' ? revokedAtUtc : s.reuseDetectedAtUtc,
    })) as unknown as AuthSessionRecord[];
  }

  async revokeSessionsByUser(
    userId: string,
    reason: string,
    revokedAtUtc: string,
    exceptSessionId?: string,
  ): Promise<readonly AuthSessionRecord[]> {
    const filter: FilterQuery<AuthSessionMongoose> = { userId, revokedAtUtc: { $exists: false } };
    if (exceptSessionId) {
      filter.sessionId = { $ne: exceptSessionId };
    }

    const sessionsToRevoke = await this.sessionModel.find(filter).lean().exec();

    await this.sessionModel
      .updateMany(filter, { $set: { revokedAtUtc, revokedReason: reason } })
      .exec();

    return sessionsToRevoke.map((s) => ({
      ...s,
      revokedAtUtc,
      revokedReason: reason,
    })) as unknown as AuthSessionRecord[];
  }

  async upsertPasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord> {
    await this.resetModel
      .updateMany({ userId: record.userId, consumed: false }, { $set: { consumed: true } })
      .exec();
    await this.resetModel
      .updateOne({ userId: record.userId }, { $set: record }, { upsert: true })
      .exec();
    return record;
  }

  async findActivePasswordResetByUser(userId: string): Promise<PasswordResetRecord | null> {
    const doc = await this.resetModel
      .findOne({ userId, consumed: false })
      .sort({ createdAtUtc: -1 })
      .lean()
      .exec();
    if (!doc) return null;
    return doc as unknown as PasswordResetRecord;
  }

  async findActivePasswordResetByLocator(
    context: AuthLoginContext,
    identifier: string,
    tenantSlug?: string,
  ): Promise<PasswordResetRecord | null> {
    const identity = await this.findIdentity(context, identifier, tenantSlug);
    if (!identity) return null;
    return this.findActivePasswordResetByUser(identity.userId);
  }

  async consumePasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord> {
    const updated = { ...record, consumed: true };
    await this.resetModel
      .updateOne({ resetId: record.resetId }, { $set: { consumed: true } })
      .exec();
    return updated;
  }

  async updatePasswordReset(record: PasswordResetRecord): Promise<PasswordResetRecord> {
    await this.resetModel.updateOne({ resetId: record.resetId }, { $set: record }).exec();
    return record;
  }

  async recordNotification(intent: AuthNotificationIntent): Promise<AuthNotificationIntent> {
    await this.notificationModel.create(intent);
    return intent;
  }

  // ── Staff identity management ──────────────────────────────────────────────

  async createStaffIdentity(record: StaffAuthRecord): Promise<StaffAuthRecord> {
    await this.tenantStaffModel.create({
      userId: record.userId,
      tenantId: record.tenantId,
      tenantSlug: record.tenantSlug,
      tenantName: record.tenantName,
      loginId: record.loginId,
      displayName: record.displayName,
      email: record.email,
      passwordHash: record.passwordHash,
      roleCode: record.roleCode,
      permissions: record.permissions,
      branchIds: record.branchIds,
      status: record.status,
      accessVersion: record.accessVersion,
      createdAtUtc: record.createdAtUtc,
    });
    return record;
  }

  async deleteStaffIdentity(userId: string): Promise<void> {
    await this.tenantStaffModel.deleteOne({ userId }).exec();
  }

  async findStaffIdentityByUserId(userId: string): Promise<StaffAuthRecord | null> {
    const doc = await this.tenantStaffModel.findOne({ userId }).lean().exec();
    if (!doc) return null;
    return {
      userId: doc.userId,
      tenantId: doc.tenantId,
      tenantSlug: doc.tenantSlug,
      tenantName: doc.tenantName,
      loginId: doc.loginId,
      displayName: doc.displayName,
      email: doc.email,
      passwordHash: doc.passwordHash,
      roleCode: doc.roleCode,
      permissions: effectivePermissions(doc.roleCode, doc.permissions),
      branchIds: Object.freeze(doc.branchIds ?? []),
      status: doc.status as StaffAuthRecord['status'],
      accessVersion: doc.accessVersion,
      createdAtUtc: doc.createdAtUtc,
    };
  }

  async updateStaffIdentityStatus(userId: string, status: 'active' | 'disabled'): Promise<void> {
    await this.tenantStaffModel.updateOne({ userId }, { $set: { status } }).exec();
  }

  async updateStaffIdentityAccess(
    userId: string,
    roleCode: string,
    permissions: readonly string[],
    branchIds: readonly string[],
  ): Promise<void> {
    await this.tenantStaffModel
      .updateOne(
        { userId },
        {
          $set: { roleCode, permissions: [...permissions], branchIds: [...branchIds] },
          $inc: { accessVersion: 1 },
        },
      )
      .exec();
  }
}
