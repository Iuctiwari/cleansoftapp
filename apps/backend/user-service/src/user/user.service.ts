import { randomBytes } from 'node:crypto';

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  HttpStatus,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import {
  Permissions,
  defaultPermissionsForRole,
  hasPermission,
  CUSTOM_ACCESS_MARKER,
  EDITABLE_ROLES,
  isBranchManagerRole,
  isOwnerRole,
  rolePermissionsWithOverride,
  sanitizeCustomPermissions,
} from '@nexoraa/shared';
import { Model, Types } from 'mongoose';

import type { UserAccessScope } from './user-auth.middleware';
import { RegisterStaffDto, StaffResponseDto, UpdateStaffDto } from './user.dto';
import { UserMongoose } from './user.schema';
import { StaffAvailability, UserStatus } from './user.types';

/** A role as the Roles screen shows it. */
export interface RoleView {
  readonly role: string;
  readonly description: string;
  /** What the role can do in this shop right now. */
  readonly permissions: string[];
  /** The platform default, for "reset". */
  readonly defaultPermissions: string[];
  /** The owner may change this role's modules. */
  readonly editable: boolean;
  /** The owner has changed it from the default. */
  readonly isCustomized: boolean;
}

@Injectable()
export class UserService {
  private readonly logger = new Logger(UserService.name);

  constructor(
    @InjectModel(UserMongoose.name)
    private readonly userModel: Model<UserMongoose>,
    private readonly configService: ConfigService,
  ) {}

  // ── Read ─────────────────────────────────────────────────────────────────

  /** No trusted scope needed — internal/system-level query (see
   *  PlatformAdminInternalGuard), used by platform-admin-service's Company
   *  Admin panel to show a tenant's staff count. */
  countActiveStaffByTenant(tenantId: string): Promise<number> {
    if (!Types.ObjectId.isValid(tenantId)) return Promise.resolve(0);
    return this.userModel
      .countDocuments({ tenantId: new Types.ObjectId(tenantId), isDeleted: false })
      .exec();
  }

  async listStaff(scope: UserAccessScope, tenantId: string): Promise<StaffResponseDto[]> {
    this.assertTenant(scope, tenantId);
    this.assertStaffRead(scope);
    const users = await this.userModel
      .find({
        tenantId: new Types.ObjectId(tenantId),
        isDeleted: false,
        ...(isBranchManagerRole(scope.roleCode)
          ? {
              // Read access includes every user assigned to the manager's
              // branch (Staff, Cashier, and its manager). Mutation rules
              // remain narrower in assertTarget/registerStaff.
              branchIds: new Types.ObjectId(scope.branchId),
            }
          : {}),
      })
      .exec();
    return users.map((user) => this.mapToDto(user));
  }

  async getStaff(scope: UserAccessScope, userId: string): Promise<StaffResponseDto> {
    if (scope.actorId !== userId) {
      this.assertStaffRead(scope);
    }
    const user = await this.userModel.findById(userId);
    if (!user || user.isDeleted) throw new NotFoundException('User not found');
    this.assertTarget(scope, user);
    return this.mapToDto(user);
  }

  // ── Register ─────────────────────────────────────────────────────────────

  /**
   * Registers a new staff member with direct credentials.
   * 1. Creates the user profile in this service.
   * 2. Calls auth-service to provision loginId + passwordHash.
   * If auth provisioning fails, rolls back by deleting the user record.
   */
  async registerStaff(
    scope: UserAccessScope,
    tenantId: string,
    dto: RegisterStaffDto,
  ): Promise<StaffResponseDto> {
    this.assertTenant(scope, tenantId);
    this.assertStaffWrite(scope);
    if (
      isBranchManagerRole(scope.roleCode) &&
      (dto.role !== 'Staff' || dto.branchIds.some((id) => id !== scope.branchId))
    ) {
      throw new ForbiddenException(
        'Branch Managers may invite Staff only to their assigned branch',
      );
    }
    if (dto.sendInvite && !dto.email?.trim()) {
      throw new BadRequestException('An email address is required to send an invitation');
    }
    if (!dto.sendInvite && !dto.password) {
      throw new BadRequestException('A password is required unless an invitation is sent');
    }
    // Invited staff set their own password via Forgot password, so the account gets
    // a random one nobody knows (never returned or emailed).
    const password = dto.password ?? `Inv!${randomBytes(18).toString('base64url')}a1`;

    // Check duplicate loginId within tenant
    const tenantOid = new Types.ObjectId(tenantId);
    const existingLoginId = await this.userModel.findOne({
      tenantId: tenantOid,
      loginId: dto.loginId.trim().toLowerCase(),
      isDeleted: false,
    });
    if (existingLoginId) {
      throw new ConflictException('A user with this login ID already exists in this workspace');
    }

    // Check duplicate email / mobileNumber
    const orClauses: Record<string, unknown>[] = [];
    if (dto.email) orClauses.push({ email: dto.email });
    if (dto.mobileNumber) orClauses.push({ mobileNumber: dto.mobileNumber });
    if (orClauses.length > 0) {
      const existing = await this.userModel.findOne({
        tenantId: tenantOid,
        isDeleted: false,
        $or: orClauses,
      });
      if (existing) {
        throw new ConflictException(
          'A user with this email or mobile number already exists in this workspace',
        );
      }
    }

    const userId = new Types.ObjectId().toString();
    const branchObjectIds = dto.branchIds.map((id) => new Types.ObjectId(id));

    const user = new this.userModel({
      _id: new Types.ObjectId(userId),
      tenantId: tenantOid,
      name: dto.name,
      loginId: dto.loginId.trim().toLowerCase(),
      email: dto.email,
      mobileNumber: dto.mobileNumber,
      department: dto.department,
      role: dto.role,
      branchIds: branchObjectIds,
      status: 'Active',
    });

    await user.save();

    // Provision auth credentials in auth-service
    let inviteSent = false;
    try {
      inviteSent = await this.provisionAuthCredentials({
        userId: user._id.toString(),
        tenantId,
        loginId: dto.loginId.trim().toLowerCase(),
        displayName: dto.name,
        email: dto.email,
        password,
        roleCode: dto.role,
        branchIds: dto.branchIds,
        sendInvite: dto.sendInvite === true,
        businessName: dto.businessName?.trim() || undefined,
      });
    } catch (err) {
      // Roll back user record if auth provisioning fails
      this.logger.error(
        `Auth provisioning failed for ${String(user._id)}, rolling back user record`,
        err,
      );
      await this.userModel.deleteOne({ _id: user._id });
      throw err;
    }

    return { ...this.mapToDto(user), ...(dto.sendInvite ? { inviteSent } : {}) };
  }

  // ── Status ────────────────────────────────────────────────────────────────

  async updateStatus(scope: UserAccessScope, userId: string, status: UserStatus): Promise<void> {
    this.assertStaffWrite(scope);
    const user = await this.userModel.findById(userId);
    if (!user || user.isDeleted) throw new NotFoundException('User not found');
    this.assertTarget(scope, user);

    user.status = status;
    await user.save();

    // Sync status to auth-service
    const authStatus = status === 'Active' ? 'active' : 'disabled';
    try {
      await this.updateAuthStatus(userId, authStatus);
    } catch (err) {
      this.logger.warn(
        `Could not sync auth status for user ${userId}: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  async updateStaff(
    scope: UserAccessScope,
    userId: string,
    dto: UpdateStaffDto,
  ): Promise<StaffResponseDto> {
    const isSelfUpdate = scope.actorId === userId;
    let hasStaffWrite = false;
    try {
      this.assertStaffWrite(scope);
      hasStaffWrite = true;
    } catch {
      if (!isSelfUpdate) {
        throw new ForbiddenException('Staff management permission is required');
      }
    }

    const user = await this.userModel.findById(userId);
    if (!user || user.isDeleted) throw new NotFoundException('User not found');
    this.assertTarget(scope, user);

    if (!hasStaffWrite && (dto.role !== undefined || dto.branchIds !== undefined)) {
      throw new ForbiddenException('You do not have permission to change roles or branches');
    }

    if (
      hasStaffWrite &&
      isBranchManagerRole(scope.roleCode) &&
      ((dto.role !== undefined && dto.role !== 'Staff') ||
        (dto.branchIds !== undefined && dto.branchIds.some((id) => id !== scope.branchId)))
    ) {
      throw new ForbiddenException('Branch Managers cannot change role or branch scope');
    }

    // Module access: only the owner decides, and only for the Staff role.
    let accessChange: { customPermissions?: string[]; resetAccess?: boolean } | undefined;
    if (dto.accessMode !== undefined) {
      if (!isOwnerRole(scope.roleCode)) {
        throw new ForbiddenException('Only the owner can change module access');
      }
      if ((dto.role ?? user.role) !== 'Staff') {
        throw new BadRequestException('Module access can only be customised for the Staff role');
      }
      if (dto.accessMode === 'custom') {
        const list = sanitizeCustomPermissions(dto.permissions ?? []);
        user.set('customPermissions', list);
        accessChange = { customPermissions: list };
      } else {
        user.set('customPermissions', undefined);
        accessChange = { resetAccess: true };
      }
    } else if (dto.role !== undefined && dto.role !== 'Staff' && user.customPermissions) {
      // Moving someone out of the Staff role drops their custom access.
      user.set('customPermissions', undefined);
    }

    if (dto.name) user.name = dto.name;
    if (dto.email !== undefined) user.email = dto.email;
    if (dto.mobileNumber !== undefined) user.mobileNumber = dto.mobileNumber;
    if (dto.department !== undefined) user.department = dto.department;
    if (dto.role) user.role = dto.role;
    if (dto.branchIds) {
      user.branchIds = dto.branchIds.map((id) => new Types.ObjectId(id));
    }

    await user.save();
    if (dto.role !== undefined || dto.branchIds !== undefined || accessChange) {
      await this.updateAuthAccess(
        userId,
        user.role,
        user.branchIds.map((id) => id.toString()),
        accessChange,
      );
    }
    return this.mapToDto(user);
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  async removeStaff(scope: UserAccessScope, userId: string): Promise<void> {
    if (!isOwnerRole(scope.roleCode)) throw new ForbiddenException('Owner permission is required');
    const user = await this.userModel.findById(userId);
    if (!user || user.isDeleted) throw new NotFoundException('User not found');
    this.assertTarget(scope, user);

    // Soft delete in User database
    await this.userModel
      .updateOne({ _id: user._id }, { $set: { isDeleted: true, status: 'Suspended' } })
      .exec();

    // Remove credentials from Auth database
    try {
      await this.deleteAuthCredentials(userId);
    } catch (err) {
      this.logger.warn(
        `Could not remove auth credentials for user ${userId}: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
  }

  // ── Roles ─────────────────────────────────────────────────────────────────

  /**
   * The roles and what each can do in this shop. Platform defaults, unless the owner chose
   * different modules for Staff or Branch Manager.
   */
  async getSystemRoles(scope: UserAccessScope): Promise<RoleView[]> {
    this.assertStaffRead(scope);
    const overrides = await this.fetchRoleOverrides(scope.tenantId);
    return this.baseRoles().map((base) => {
      const editable = EDITABLE_ROLES.includes(base.role);
      const chosen = overrides.get(base.role);
      const permissions =
        editable && chosen
          ? rolePermissionsWithOverride(base.role, chosen).filter((p) => p !== CUSTOM_ACCESS_MARKER)
          : base.permissions;
      return {
        ...base,
        permissions: [...permissions],
        defaultPermissions: base.permissions,
        editable,
        isCustomized: editable && !!chosen,
      };
    });
  }

  /** Owner only: change (or, with null, reset) what a role gets in this shop. */
  async setRoleAccess(
    scope: UserAccessScope,
    role: string,
    permissions: string[] | null,
  ): Promise<RoleView[]> {
    if (!isOwnerRole(scope.roleCode)) {
      throw new ForbiddenException('Only the owner can change what a role can access');
    }
    if (!EDITABLE_ROLES.includes(role)) {
      throw new BadRequestException(`The ${role} role cannot be customised`);
    }
    const authBaseUrl = this.configService.getOrThrow<string>('AUTH_SERVICE_INTERNAL_URL');
    const secret = this.configService.getOrThrow<string>('INTERNAL_SERVICE_SECRET');
    const apiVersion = this.configService.get<string>('API_VERSION', 'v1');
    const apiPrefix = this.configService.get<string>('API_PREFIX', 'api');
    const response = await fetch(
      `${authBaseUrl}/${apiPrefix}/${apiVersion}/internal/tenants/${encodeURIComponent(scope.tenantId)}/roles/${encodeURIComponent(role)}`,
      {
        method: permissions === null ? 'DELETE' : 'PUT',
        headers: { 'Content-Type': 'application/json', 'x-internal-secret': secret },
        ...(permissions === null
          ? {}
          : { body: JSON.stringify({ permissions: sanitizeCustomPermissions(permissions) }) }),
      },
    );
    if (!response.ok) throw new Error(`Role access update failed (${response.status})`);
    return this.getSystemRoles(scope);
  }

  private async fetchRoleOverrides(tenantId: string): Promise<Map<string, string[]>> {
    try {
      const authBaseUrl = this.configService.getOrThrow<string>('AUTH_SERVICE_INTERNAL_URL');
      const secret = this.configService.getOrThrow<string>('INTERNAL_SERVICE_SECRET');
      const apiVersion = this.configService.get<string>('API_VERSION', 'v1');
      const apiPrefix = this.configService.get<string>('API_PREFIX', 'api');
      const response = await fetch(
        `${authBaseUrl}/${apiPrefix}/${apiVersion}/internal/tenants/${encodeURIComponent(tenantId)}/roles`,
        { headers: { 'x-internal-secret': secret } },
      );
      if (!response.ok) return new Map();
      const body = (await response.json()) as
        | Array<{ roleCode: string; permissions: string[] }>
        | { data?: Array<{ roleCode: string; permissions: string[] }> };
      const rows = Array.isArray(body) ? body : (body.data ?? []);
      return new Map(rows.map((row) => [row.roleCode, row.permissions]));
    } catch {
      // Showing the defaults is better than failing the whole screen.
      return new Map();
    }
  }

  private baseRoles(): Array<{ role: string; description: string; permissions: string[] }> {
    return [
      {
        role: 'Owner',
        description: 'Full access to all business settings, analytics, and branches.',
        permissions: [...defaultPermissionsForRole('Owner')],
      },
      {
        role: 'Branch Manager',
        description: 'Can manage daily operations and staff for assigned branches.',
        permissions: [...defaultPermissionsForRole('Branch Manager')],
      },
      {
        role: 'Staff',
        description: 'Standard worker role with basic access to assigned services.',
        permissions: [...defaultPermissionsForRole('Staff')],
      },
      {
        role: 'Cashier',
        description: 'Can process payments and manage the cash register.',
        permissions: ['Process Payments', 'Issue Refunds', 'End of Day Reports'],
      },
    ];
  }

  // ── Availability ──────────────────────────────────────────────────────────

  async getMe(scope: UserAccessScope): Promise<StaffResponseDto> {
    const user = await this.userModel.findOne({
      _id: new Types.ObjectId(scope.actorId),
      tenantId: new Types.ObjectId(scope.tenantId),
      isDeleted: false,
    });
    if (!user) throw new NotFoundException('User not found');
    return this.mapToDto(user);
  }

  async updateAvailability(
    scope: UserAccessScope,
    userId: string,
    availability: StaffAvailability,
  ): Promise<StaffResponseDto> {
    if (
      scope.actorId !== userId &&
      !isOwnerRole(scope.roleCode) &&
      !isBranchManagerRole(scope.roleCode)
    ) {
      throw new ForbiddenException('Staff can only update their own availability');
    }
    const user = await this.userModel.findOne({
      _id: new Types.ObjectId(userId),
      tenantId: new Types.ObjectId(scope.tenantId),
      isDeleted: false,
    });
    if (!user) throw new NotFoundException('User not found');
    this.assertTarget(scope, user);

    user.availability = availability;
    await user.save();
    return this.mapToDto(user);
  }

  private assertTenant(scope: UserAccessScope, tenantId: string): void {
    if (scope.tenantId !== tenantId) throw new ForbiddenException('Tenant access is forbidden');
  }

  private assertStaffRead(scope: UserAccessScope): void {
    if (
      !(isOwnerRole(scope.roleCode) || isBranchManagerRole(scope.roleCode)) ||
      !hasPermission(scope.roleCode, scope.permissions, Permissions.staffRead)
    ) {
      throw new ForbiddenException('Staff read permission is required');
    }
  }

  private assertStaffWrite(scope: UserAccessScope): void {
    if (
      !(isOwnerRole(scope.roleCode) || isBranchManagerRole(scope.roleCode)) ||
      !hasPermission(scope.roleCode, scope.permissions, Permissions.staffWrite)
    ) {
      throw new ForbiddenException('Staff management permission is required');
    }
  }

  private assertTarget(scope: UserAccessScope, user: UserMongoose): void {
    const docId = (user as unknown as { _id: Types.ObjectId })._id?.toString() ?? '';
    if (scope.actorId === docId) return;
    const target = user as unknown as {
      tenantId: Types.ObjectId;
      branchIds: Types.ObjectId[];
      role: string;
    };
    if (
      target.tenantId.toString() !== scope.tenantId ||
      (isBranchManagerRole(scope.roleCode) &&
        (target.role !== 'Staff' ||
          !target.branchIds.some((id) => id.toString() === scope.branchId)))
    ) {
      throw new NotFoundException('User not found');
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  private async provisionAuthCredentials(params: {
    userId: string;
    tenantId: string;
    loginId: string;
    displayName: string;
    email?: string;
    password: string;
    roleCode: string;
    branchIds: string[];
    sendInvite?: boolean;
    businessName?: string;
  }): Promise<boolean> {
    const authBaseUrl = this.configService.getOrThrow<string>('AUTH_SERVICE_INTERNAL_URL');
    const secret = this.configService.getOrThrow<string>('INTERNAL_SERVICE_SECRET');
    const apiVersion = this.configService.get<string>('API_VERSION', 'v1');
    const apiPrefix = this.configService.get<string>('API_PREFIX', 'api');

    // Fetch tenant slug from tenant record — required by auth-service
    const tenantSlug = this.configService.get<string>('AUTH_TENANT_SLUG', params.tenantId);

    const url = `${authBaseUrl}/${apiPrefix}/${apiVersion}/internal/staff/provision`;
    const body = JSON.stringify({
      userId: params.userId,
      tenantId: params.tenantId,
      tenantSlug,
      // Shown to staff as their business name (login response, invitation email).
      tenantName: params.businessName ?? tenantSlug,
      loginId: params.loginId,
      displayName: params.displayName,
      email: params.email,
      password: params.password,
      roleCode: params.roleCode,
      branchIds: params.branchIds,
      sendInvite: params.sendInvite === true,
    });

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-internal-secret': secret,
      },
      body,
    });

    if (!response.ok) {
      const text = await response.text();
      if (response.status === HttpStatus.CONFLICT) {
        // auth-service refused the login ID (e.g. it is a shop owner's email):
        // pass its explanation on instead of a generic server error.
        let message =
          'This email is already used to sign in as a shop owner. Use a different email or login ID for this staff member.';
        try {
          const body = JSON.parse(text) as { message?: unknown };
          if (typeof body.message === 'string' && body.message.trim()) message = body.message;
        } catch {
          // keep the generic message
        }
        throw new ConflictException(message);
      }
      throw new Error(`Auth provisioning failed (${response.status}): ${text}`);
    }
    const result = (await response.json().catch(() => ({}))) as {
      inviteSent?: boolean;
      data?: { inviteSent?: boolean };
    };
    return (result.data ?? result).inviteSent === true;
  }

  private async updateAuthStatus(userId: string, status: 'active' | 'disabled'): Promise<void> {
    const authBaseUrl = this.configService.getOrThrow<string>('AUTH_SERVICE_INTERNAL_URL');
    const secret = this.configService.getOrThrow<string>('INTERNAL_SERVICE_SECRET');
    const apiVersion = this.configService.get<string>('API_VERSION', 'v1');
    const apiPrefix = this.configService.get<string>('API_PREFIX', 'api');

    const url = `${authBaseUrl}/${apiPrefix}/${apiVersion}/internal/staff/${userId}/status`;
    await fetch(url, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'x-internal-secret': secret,
      },
      body: JSON.stringify({ status }),
    });
  }

  private async deleteAuthCredentials(userId: string): Promise<void> {
    const authBaseUrl = this.configService.getOrThrow<string>('AUTH_SERVICE_INTERNAL_URL');
    const secret = this.configService.getOrThrow<string>('INTERNAL_SERVICE_SECRET');
    const apiVersion = this.configService.get<string>('API_VERSION', 'v1');
    const apiPrefix = this.configService.get<string>('API_PREFIX', 'api');

    const url = `${authBaseUrl}/${apiPrefix}/${apiVersion}/internal/staff/${userId}`;
    await fetch(url, {
      method: 'DELETE',
      headers: {
        'x-internal-secret': secret,
      },
    });
  }

  private async updateAuthAccess(
    userId: string,
    roleCode: string,
    branchIds: string[],
    access?: { customPermissions?: string[]; resetAccess?: boolean },
  ): Promise<void> {
    const authBaseUrl = this.configService.getOrThrow<string>('AUTH_SERVICE_INTERNAL_URL');
    const secret = this.configService.getOrThrow<string>('INTERNAL_SERVICE_SECRET');
    const apiVersion = this.configService.get<string>('API_VERSION', 'v1');
    const apiPrefix = this.configService.get<string>('API_PREFIX', 'api');
    const response = await fetch(
      `${authBaseUrl}/${apiPrefix}/${apiVersion}/internal/staff/${userId}/access`,
      {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', 'x-internal-secret': secret },
        body: JSON.stringify({ roleCode, branchIds, ...access }),
      },
    );
    if (!response.ok) {
      throw new Error(`Auth access update failed (${response.status})`);
    }
  }

  private mapToDto(user: UserMongoose): StaffResponseDto {
    const doc = user as unknown as {
      _id: Types.ObjectId;
      tenantId: Types.ObjectId;
      name: string;
      loginId: string;
      email?: string;
      mobileNumber?: string;
      department?: string;
      role: string;
      branchIds: Types.ObjectId[];
      status: string;
      availability?: string;
      customPermissions?: string[];
      createdAt: Date;
      updatedAt: Date;
    };
    return {
      userId: doc._id.toString(),
      tenantId: doc.tenantId.toString(),
      name: doc.name,
      loginId: doc.loginId,
      email: doc.email,
      mobileNumber: doc.mobileNumber,
      department: doc.department,
      role: doc.role as StaffResponseDto['role'],
      branchIds: doc.branchIds.map((id) => id.toString()),
      status: doc.status as StaffResponseDto['status'],
      availability: (doc.availability as StaffResponseDto['availability']) || 'Available',
      accessMode: doc.customPermissions ? 'custom' : 'default',
      permissions: doc.customPermissions ? [...doc.customPermissions] : [],
      createdAt: doc.createdAt?.toISOString?.() ?? new Date().toISOString(),
      updatedAt: doc.updatedAt?.toISOString?.() ?? new Date().toISOString(),
    };
  }
}
