import { randomBytes } from 'node:crypto';

import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';

import type { PaginatedResult } from '../platform/platform.types';
import { BranchMongoose } from './branch.mongoose.schema';
import type {
  BranchQueryFilters,
  BranchRecord,
  BranchRepository,
  BranchUpdatePatch,
} from './branch.types';

/** 24 hex chars — matches tenant-service's generateTenantId()/generateUserId() format. */
export function generateBranchId(): string {
  return randomBytes(12).toString('hex');
}

function toRecord(doc: Record<string, unknown>): BranchRecord {
  return {
    branchId: doc.branchId as string,
    tenantId: doc.tenantId as string,
    branchName: doc.branchName as string,
    code: (doc.code as string | undefined) ?? undefined,
    streetAddress: (doc.streetAddress as string) ?? '',
    city: (doc.city as string) ?? '',
    state: (doc.state as string) ?? '',
    country: (doc.country as string) ?? '',
    postalCode: (doc.postalCode as string) ?? '',
    phone: doc.phone as string,
    email: doc.email as string,
    openingTime: doc.openingTime as string | undefined,
    closingTime: doc.closingTime as string | undefined,
    managerId: doc.managerId as string | undefined,
    isHeadOffice: doc.isHeadOffice as boolean,
    status: doc.status as BranchRecord['status'],
    createdAt: doc.createdAt as string,
    updatedAt: doc.updatedAt as string,
  };
}

@Injectable()
export class MongoBranchRepository implements BranchRepository {
  constructor(
    @InjectModel(BranchMongoose.name)
    private readonly branchModel: Model<BranchMongoose>,
  ) {}

  async findByBranchIdAndTenant(branchId: string, tenantId: string): Promise<BranchRecord | null> {
    const doc = await this.branchModel.findOne({ branchId, tenantId }).lean().exec();
    return doc ? toRecord(doc) : null;
  }

  async findByCodeAndTenant(code: string, tenantId: string): Promise<BranchRecord | null> {
    const doc = await this.branchModel
      .findOne({ tenantId, code: code.toUpperCase() })
      .lean()
      .exec();
    return doc ? toRecord(doc) : null;
  }

  async listCodesByTenant(tenantId: string): Promise<readonly string[]> {
    const docs = await this.branchModel
      .find({ tenantId, code: { $exists: true, $ne: '' } })
      .select({ _id: 0, code: 1 })
      .lean()
      .exec();
    return docs.flatMap((doc) =>
      typeof doc.code === 'string' && doc.code.length > 0 ? [doc.code.toUpperCase()] : [],
    );
  }

  async list(
    tenantId: string,
    filters: BranchQueryFilters,
    page: { page: number; pageSize: number },
  ): Promise<PaginatedResult<BranchRecord>> {
    const query: Record<string, unknown> = { tenantId };
    if (filters.branchId) query.branchId = filters.branchId;
    if (filters.status) {
      query.status = filters.status;
    }
    if (filters.managerId) {
      query.managerId = filters.managerId;
    }

    const skip = (page.page - 1) * page.pageSize;
    const [docs, total] = await Promise.all([
      this.branchModel
        .find(query)
        .sort({ isHeadOffice: -1, createdAt: 1 })
        .skip(skip)
        .limit(page.pageSize)
        .lean()
        .exec(),
      this.branchModel.countDocuments(query).exec(),
    ]);

    return {
      items: docs.map((doc) => toRecord(doc)),
      page: page.page,
      pageSize: page.pageSize,
      total,
    };
  }

  async countActiveByTenant(tenantId: string): Promise<number> {
    return this.branchModel.countDocuments({ tenantId, status: 'active' }).exec();
  }

  async create(record: BranchRecord): Promise<BranchRecord> {
    await this.branchModel.create(record);
    return record;
  }

  async update(
    branchId: string,
    tenantId: string,
    patch: BranchUpdatePatch,
  ): Promise<BranchRecord> {
    const setFields: Record<string, unknown> = {};
    const unsetFields: Record<string, ''> = {};

    for (const [key, value] of Object.entries(patch)) {
      if (value === null) {
        unsetFields[key] = '';
      } else if (value !== undefined) {
        setFields[key] = value;
      }
    }

    const update: Record<string, unknown> = {};
    if (Object.keys(setFields).length > 0) update.$set = setFields;
    if (Object.keys(unsetFields).length > 0) update.$unset = unsetFields;

    const doc = await this.branchModel
      .findOneAndUpdate({ branchId, tenantId }, update, { new: true })
      .lean()
      .exec();

    if (!doc) {
      throw new Error(`Branch ${branchId} not found for tenant ${tenantId} during update`);
    }

    return toRecord(doc);
  }
}
