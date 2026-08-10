import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import {
  BranchMongoose,
  TenantMongoose,
  TenantOwnerMongoose,
  TenantServiceMongoose,
} from './tenant.mongoose.schema';
import type {
  BranchRecord,
  RegisterTenantOutput,
  TenantOwnerRecord,
  TenantRecord,
  TenantRepository,
  TenantServiceRecord,
  TenantStatus,
} from './tenant.types';

@Injectable()
export class MongoTenantRepository implements TenantRepository {
  constructor(
    @InjectModel(TenantMongoose.name)
    private readonly tenantModel: Model<TenantMongoose>,
    @InjectModel(TenantOwnerMongoose.name)
    private readonly ownerModel: Model<TenantOwnerMongoose>,
    @InjectModel(BranchMongoose.name)
    private readonly branchModel: Model<BranchMongoose>,
    @InjectModel(TenantServiceMongoose.name)
    private readonly tenantServiceModel: Model<TenantServiceMongoose>,
  ) {}

  async findByEmail(email: string): Promise<TenantOwnerRecord | null> {
    const normalised = email.trim().toLowerCase();
    const doc = await this.ownerModel.findOne({ email: normalised }).lean().exec();
    if (!doc) return null;
    return this.mapOwner(doc);
  }

  async findBySlug(slug: string): Promise<TenantRecord | null> {
    const doc = await this.tenantModel.findOne({ slug }).lean().exec();
    if (!doc) return null;
    return this.mapTenant(doc);
  }

  async findById(tenantId: string): Promise<TenantRecord | null> {
    const doc = await this.tenantModel.findOne({ tenantId }).lean().exec();
    if (!doc) return null;
    return this.mapTenant(doc);
  }

  async listBranches(tenantId: string): Promise<BranchRecord[]> {
    const docs = await this.branchModel.find({ tenantId }).lean().exec();
    return docs.map((d) => this.mapBranch(d));
  }

  async updateStatus(tenantId: string, status: TenantStatus): Promise<void> {
    const now = new Date().toISOString();
    await this.tenantModel.updateOne({ tenantId }, { $set: { status, updatedAt: now } }).exec();
  }

  async createTenant(
    tenant: TenantRecord,
    owner: TenantOwnerRecord,
    branch: BranchRecord,
    services: TenantServiceRecord[],
  ): Promise<RegisterTenantOutput> {
    // Use insertMany / create in sequence — a transaction would require a replica set;
    // for development the in-order inserts are sufficient.
    await this.tenantModel.create(tenant);
    await this.ownerModel.create(owner);
    await this.branchModel.create(branch);
    if (services.length > 0) {
      await this.tenantServiceModel.insertMany(services);
    }

    return {
      tenantId: tenant.tenantId,
      slug: tenant.slug,
      ownerUserId: owner.userId,
      businessName: tenant.businessName,
      message: 'Account created successfully',
    };
  }

  // ─── Mapping helpers ──────────────────────────────────────────────────────

  private mapTenant(doc: Record<string, unknown>): TenantRecord {
    return {
      tenantId: doc.tenantId as string,
      slug: doc.slug as string,
      businessName: doc.businessName as string,
      businessType: doc.businessType as TenantRecord['businessType'],
      ownerName: doc.ownerName as string,
      ownerEmail: doc.ownerEmail as string,
      ownerPhone: doc.ownerPhone as string,
      ownerUserId: doc.ownerUserId as string,
      taxEnabled: doc.taxEnabled as boolean,
      defaultTaxPct: doc.defaultTaxPct as number,
      subscriptionPlanId: doc.subscriptionPlanId as string,
      status: doc.status as TenantRecord['status'],
      createdAt: doc.createdAt as string,
      updatedAt: doc.updatedAt as string,
    };
  }

  private mapOwner(doc: Record<string, unknown>): TenantOwnerRecord {
    return {
      userId: doc.userId as string,
      tenantId: doc.tenantId as string,
      slug: doc.slug as string,
      tenantName: doc.tenantName as string,
      displayName: doc.displayName as string,
      email: doc.email as string,
      mobileNumber: doc.mobileNumber as string,
      passwordHash: doc.passwordHash as string,
      roleCode: doc.roleCode as string,
      permissions: (doc.permissions as string[]) ?? [],
      status: doc.status as TenantOwnerRecord['status'],
      accessVersion: doc.accessVersion as number,
      createdAt: doc.createdAt as string,
    };
  }

  private mapBranch(doc: Record<string, unknown>): BranchRecord {
    return {
      branchId: doc.branchId as string,
      tenantId: doc.tenantId as string,
      branchName: doc.branchName as string,
      streetAddress: (doc.streetAddress as string) ?? '',
      city: (doc.city as string) ?? '',
      state: (doc.state as string) ?? '',
      country: (doc.country as string) ?? '',
      postalCode: (doc.postalCode as string) ?? '',
      phone: doc.phone as string,
      email: doc.email as string,
      isHeadOffice: doc.isHeadOffice as boolean,
      status: doc.status as BranchRecord['status'],
      createdAt: doc.createdAt as string,
      updatedAt: doc.updatedAt as string,
    };
  }
}
