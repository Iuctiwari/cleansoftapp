import { Injectable } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, Model } from 'mongoose';

import { generateTenantId } from './tenant.crypto';
import {
  BranchMongoose,
  TenantMongoose,
  TenantOwnerMongoose,
  TenantServiceMongoose,
} from './tenant.mongoose.schema';
import type {
  BranchRecord,
  CatalogProvisioningCandidate,
  CompleteTenantOnboardingInput,
  CompleteTenantOnboardingOutput,
  RegisterTenantOutput,
  TenantOwnerRecord,
  TenantRecord,
  TenantRepository,
  TenantServiceRecord,
  TenantStatus,
  UpdateTenantProfileInput,
} from './tenant.types';

@Injectable()
export class MongoTenantRepository implements TenantRepository {
  constructor(
    @InjectConnection()
    private readonly connection: Connection,
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

  async listCatalogProvisioningCandidates(): Promise<CatalogProvisioningCandidate[]> {
    const tenants = await this.tenantModel
      .find({ status: { $in: ['Active', 'PendingVerification'] } })
      .lean()
      .exec();
    const enabledServices = await this.tenantServiceModel
      .find({ isEnabled: true, tenantId: { $in: tenants.map((tenant) => tenant.tenantId) } })
      .lean()
      .exec();
    return tenants.map((tenant) => ({
      tenantId: tenant.tenantId,
      ownerUserId: tenant.ownerUserId,
      businessTypes: [
        ...new Set(
          enabledServices
            .filter((service) => service.tenantId === tenant.tenantId)
            .map((service) => service.serviceType),
        ),
      ],
    }));
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

  async completeOnboarding(
    tenantId: string,
    input: CompleteTenantOnboardingInput,
  ): Promise<CompleteTenantOnboardingOutput> {
    const session = await this.connection.startSession();
    const now = new Date().toISOString();

    try {
      await session.withTransaction(async () => {
        const tenantResult = await this.tenantModel
          .updateOne(
            { tenantId },
            {
              $set: {
                businessName: input.businessName,
                businessType: input.businessType,
                ownerName: input.ownerName,
                ownerEmail: input.email,
                ownerPhone: input.mobileNumber,
                updatedAt: now,
              },
            },
            { session },
          )
          .exec();
        if (tenantResult.matchedCount !== 1) {
          throw new Error('Tenant record is missing during onboarding');
        }

        const ownerResult = await this.ownerModel
          .updateOne(
            { tenantId },
            {
              $set: {
                tenantName: input.businessName,
                displayName: input.ownerName,
                email: input.email,
                mobileNumber: input.mobileNumber,
              },
            },
            { session },
          )
          .exec();
        if (ownerResult.matchedCount !== 1) {
          throw new Error('Tenant owner record is missing during onboarding');
        }

        const branchResult = await this.branchModel
          .updateOne(
            { tenantId, isHeadOffice: true },
            {
              $set: {
                branchName: input.branch.branchName,
                streetAddress: input.branch.streetAddress,
                city: input.branch.city,
                postalCode: input.branch.postalCode,
                phone: input.branch.phone,
                email: input.branch.email,
                updatedAt: now,
              },
              $unset: { state: '', country: '' },
            },
            { session },
          )
          .exec();
        if (branchResult.matchedCount !== 1) {
          throw new Error('Head-office branch is missing during onboarding');
        }

        await this.tenantServiceModel.bulkWrite(
          input.services.map((serviceType) => ({
            updateOne: {
              filter: { tenantId, serviceType },
              update: {
                $set: { isEnabled: true },
                $setOnInsert: {
                  tenantServiceId: generateTenantId(),
                  tenantId,
                  serviceType,
                  createdAt: now,
                },
              },
              upsert: true,
            },
          })),
          { session },
        );
      });

      return {
        tenantId,
        message: 'Onboarding completed successfully',
      };
    } finally {
      await session.endSession();
    }
  }

  async updateProfile(tenantId: string, input: UpdateTenantProfileInput): Promise<void> {
    const session = await this.connection.startSession();
    const now = new Date().toISOString();

    try {
      await session.withTransaction(async () => {
        const tenantUpdate: Record<string, string> = { updatedAt: now };
        const ownerUpdate: Record<string, string> = {};
        const branchUpdate: Record<string, string> = { updatedAt: now };

        if (input.ownerName) {
          tenantUpdate.ownerName = input.ownerName;
          ownerUpdate.displayName = input.ownerName;
        }
        if (input.mobileNumber) {
          tenantUpdate.ownerPhone = input.mobileNumber;
          ownerUpdate.mobileNumber = input.mobileNumber;
        }
        if (input.businessName) {
          tenantUpdate.businessName = input.businessName;
          ownerUpdate.tenantName = input.businessName;
        }
        if (input.location) {
          branchUpdate.city = input.location;
        }

        if (Object.keys(tenantUpdate).length > 1) {
          // More than just updatedAt
          await this.tenantModel
            .updateOne({ tenantId }, { $set: tenantUpdate }, { session })
            .exec();
        }
        if (Object.keys(ownerUpdate).length > 0) {
          await this.ownerModel.updateOne({ tenantId }, { $set: ownerUpdate }, { session }).exec();
        }
        if (Object.keys(branchUpdate).length > 1) {
          // More than just updatedAt
          await this.branchModel
            .updateOne({ tenantId, isHeadOffice: true }, { $set: branchUpdate }, { session })
            .exec();
        }
      });
    } finally {
      await session.endSession();
    }
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
