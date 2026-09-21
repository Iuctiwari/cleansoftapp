import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { ModuleKey } from './module-key.enum';
import { TenantModuleAccessMongoose } from './tenant-module-access.mongoose.schema';
import type { TenantModuleAccessRecord, TenantModuleAccessRepository } from './module-access.types';

function toRecord(
  document: TenantModuleAccessMongoose & { _id: Types.ObjectId },
): TenantModuleAccessRecord {
  return {
    id: document._id.toString(),
    tenantId: document.tenantId,
    moduleKey: document.moduleKey,
    isEnabled: document.isEnabled,
    customLimit: document.customLimit,
    overriddenByAdminUserId: document.overriddenByAdminUserId,
    updatedAt: (document as unknown as { updatedAt: Date }).updatedAt,
  };
}

@Injectable()
export class MongoTenantModuleAccessRepository implements TenantModuleAccessRepository {
  constructor(
    @InjectModel(TenantModuleAccessMongoose.name)
    private readonly model: Model<TenantModuleAccessMongoose>,
  ) {}

  async findAccess(
    tenantId: string,
    moduleKey: ModuleKey,
  ): Promise<TenantModuleAccessRecord | null> {
    const document = await this.model.findOne({ tenantId, moduleKey }).exec();
    return document ? toRecord(document) : null;
  }

  async listForTenant(tenantId: string): Promise<readonly TenantModuleAccessRecord[]> {
    const documents = await this.model.find({ tenantId }).exec();
    return documents.map((document) => toRecord(document));
  }

  async setAccess(
    tenantId: string,
    moduleKey: ModuleKey,
    input: { isEnabled: boolean; customLimit?: unknown; overriddenByAdminUserId?: string },
  ): Promise<TenantModuleAccessRecord> {
    const document = await this.model
      .findOneAndUpdate(
        { tenantId, moduleKey },
        { $set: { ...input } },
        { new: true, upsert: true },
      )
      .exec();
    return toRecord(document);
  }
}
