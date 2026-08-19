import { ConflictException, Injectable, NotFoundException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { RegisterStaffDto, StaffResponseDto, UpdateStaffDto } from './user.dto';
import { UserMongoose } from './user.schema';
import { UserStatus } from './user.types';

@Injectable()
export class UserService {
  private readonly logger = new Logger(UserService.name);

  constructor(
    @InjectModel(UserMongoose.name)
    private readonly userModel: Model<UserMongoose>,
    private readonly configService: ConfigService,
  ) {}

  // ── Read ─────────────────────────────────────────────────────────────────

  async listStaff(tenantId: string): Promise<StaffResponseDto[]> {
    const users = await this.userModel
      .find({ tenantId: new Types.ObjectId(tenantId), isDeleted: false })
      .exec();
    return users.map((user) => this.mapToDto(user));
  }

  // ── Register ─────────────────────────────────────────────────────────────

  /**
   * Registers a new staff member with direct credentials.
   * 1. Creates the user profile in this service.
   * 2. Calls auth-service to provision loginId + passwordHash.
   * If auth provisioning fails, rolls back by deleting the user record.
   */
  async registerStaff(tenantId: string, dto: RegisterStaffDto): Promise<StaffResponseDto> {
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
    try {
      await this.provisionAuthCredentials({
        userId: user._id.toString(),
        tenantId,
        loginId: dto.loginId.trim().toLowerCase(),
        displayName: dto.name,
        email: dto.email,
        password: dto.password,
        roleCode: dto.role,
      });
    } catch (err) {
      // Roll back user record if auth provisioning fails
      this.logger.error(`Auth provisioning failed for ${user._id}, rolling back user record`, err);
      await this.userModel.deleteOne({ _id: user._id });
      throw err;
    }

    return this.mapToDto(user);
  }

  // ── Status ────────────────────────────────────────────────────────────────

  async updateStatus(userId: string, status: UserStatus): Promise<void> {
    const user = await this.userModel.findById(userId);
    if (!user || user.isDeleted) throw new NotFoundException('User not found');

    user.status = status;
    await user.save();

    // Sync status to auth-service
    const authStatus = status === 'Active' ? 'active' : 'disabled';
    try {
      await this.updateAuthStatus(userId, authStatus);
    } catch (err) {
      this.logger.warn(`Could not sync auth status for user ${userId}: ${err}`);
    }
  }

  // ── Update ────────────────────────────────────────────────────────────────

  async updateStaff(userId: string, dto: UpdateStaffDto): Promise<StaffResponseDto> {
    const user = await this.userModel.findById(userId);
    if (!user || user.isDeleted) throw new NotFoundException('User not found');

    if (dto.name) user.name = dto.name;
    if (dto.email !== undefined) user.email = dto.email;
    if (dto.mobileNumber !== undefined) user.mobileNumber = dto.mobileNumber;
    if (dto.department !== undefined) user.department = dto.department;
    if (dto.role) user.role = dto.role;
    if (dto.branchIds) {
      user.branchIds = dto.branchIds.map((id) => new Types.ObjectId(id));
    }

    await user.save();
    return this.mapToDto(user);
  }

  // ── Remove ────────────────────────────────────────────────────────────────

  async removeStaff(userId: string): Promise<void> {
    const user = await this.userModel.findById(userId);
    if (!user || user.isDeleted) throw new NotFoundException('User not found');

    // Soft delete in User database
    await this.userModel
      .updateOne({ _id: user._id }, { $set: { isDeleted: true, status: 'Suspended' } })
      .exec();

    // Remove credentials from Auth database
    try {
      await this.deleteAuthCredentials(userId);
    } catch (err) {
      this.logger.warn(`Could not remove auth credentials for user ${userId}: ${err}`);
    }
  }

  // ── Roles ─────────────────────────────────────────────────────────────────

  getSystemRoles() {
    return [
      {
        role: 'Owner',
        description: 'Full access to all business settings, analytics, and branches.',
        permissions: ['Manage Business', 'Manage Staff', 'View Analytics', 'Manage Billing'],
      },
      {
        role: 'Branch Manager',
        description: 'Can manage daily operations and staff for assigned branches.',
        permissions: ['Manage Branch Schedule', 'View Branch Analytics', 'Manage Cashiers'],
      },
      {
        role: 'Staff',
        description: 'Standard worker role with basic access to assigned services.',
        permissions: ['View Schedule', 'Manage Appointments', 'Basic Profile Update'],
      },
      {
        role: 'Cashier',
        description: 'Can process payments and manage the cash register.',
        permissions: ['Process Payments', 'Issue Refunds', 'End of Day Reports'],
      },
    ];
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
  }): Promise<void> {
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
      tenantName: tenantSlug,
      loginId: params.loginId,
      displayName: params.displayName,
      email: params.email,
      password: params.password,
      roleCode: params.roleCode,
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
      throw new Error(`Auth provisioning failed (${response.status}): ${text}`);
    }
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
      createdAt: doc.createdAt?.toISOString?.() ?? new Date().toISOString(),
      updatedAt: doc.updatedAt?.toISOString?.() ?? new Date().toISOString(),
    };
  }
}
