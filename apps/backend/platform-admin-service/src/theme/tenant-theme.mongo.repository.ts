import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { TenantThemeMongoose } from './tenant-theme.mongoose.schema';
import type { SetTenantThemeInput, TenantThemeRecord, TenantThemeRepository } from './theme.types';

function toRecord(document: TenantThemeMongoose & { _id: Types.ObjectId }): TenantThemeRecord {
  return {
    id: document._id.toString(),
    tenantId: document.tenantId,
    primaryColorHex: document.primaryColorHex,
    secondaryColorHex: document.secondaryColorHex,
    accentColorHex: document.accentColorHex,
    darkThemeEnabled: document.darkThemeEnabled,
    customAppTitle: document.customAppTitle,
    logoUrl: document.logoUrl,
    bannerUrl: document.bannerUrl,
    allowShopThemeOverride: document.allowShopThemeOverride,
    updatedByAdminUserId: document.updatedByAdminUserId,
    createdAt: (document as unknown as { createdAt: Date }).createdAt,
    updatedAt: (document as unknown as { updatedAt: Date }).updatedAt,
  };
}

@Injectable()
export class MongoTenantThemeRepository implements TenantThemeRepository {
  constructor(
    @InjectModel(TenantThemeMongoose.name)
    private readonly model: Model<TenantThemeMongoose>,
  ) {}

  async findByTenantId(tenantId: string): Promise<TenantThemeRecord | null> {
    const document = await this.model.findOne({ tenantId }).exec();
    return document ? toRecord(document) : null;
  }

  async upsert(
    tenantId: string,
    input: SetTenantThemeInput,
    updatedByAdminUserId: string,
  ): Promise<TenantThemeRecord> {
    const document = await this.model
      .findOneAndUpdate(
        { tenantId },
        { $set: { ...input, updatedByAdminUserId } },
        { new: true, upsert: true },
      )
      .exec();
    return toRecord(document);
  }
}
