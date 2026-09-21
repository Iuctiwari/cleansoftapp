import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { TenantSubscriptionMongoose } from './tenant-subscription.mongoose.schema';
import type {
  SubscriptionPlanKey,
  TenantSubscriptionRecord,
  TenantSubscriptionRepository,
  TenantSubscriptionStatus,
} from './subscription.types';

function toRecord(
  document: TenantSubscriptionMongoose & { _id: Types.ObjectId },
): TenantSubscriptionRecord {
  return {
    id: document._id.toString(),
    tenantId: document.tenantId,
    planKey: document.planKey,
    status: document.status,
    startDate: document.startDate,
    endDate: document.endDate,
    trialEndsAt: document.trialEndsAt,
    branchLimit: document.branchLimit,
    staffLimit: document.staffLimit,
    monthlyOrderLimit: document.monthlyOrderLimit,
    billingCycle: document.billingCycle,
    autoRenew: document.autoRenew,
    notes: document.notes,
    updatedByAdminUserId: document.updatedByAdminUserId,
    createdAt: (document as unknown as { createdAt: Date }).createdAt,
    updatedAt: (document as unknown as { updatedAt: Date }).updatedAt,
  };
}

@Injectable()
export class MongoTenantSubscriptionRepository implements TenantSubscriptionRepository {
  constructor(
    @InjectModel(TenantSubscriptionMongoose.name)
    private readonly model: Model<TenantSubscriptionMongoose>,
  ) {}

  async findByTenantId(tenantId: string): Promise<TenantSubscriptionRecord | null> {
    const document = await this.model.findOne({ tenantId }).exec();
    return document ? toRecord(document) : null;
  }

  async upsert(
    tenantId: string,
    input: Partial<Omit<TenantSubscriptionRecord, 'id' | 'tenantId' | 'createdAt' | 'updatedAt'>>,
  ): Promise<TenantSubscriptionRecord> {
    const document = await this.model
      .findOneAndUpdate({ tenantId }, { $set: input }, { new: true, upsert: true })
      .exec();
    return toRecord(document);
  }

  async findManyByTenantIds(
    tenantIds: readonly string[],
  ): Promise<readonly TenantSubscriptionRecord[]> {
    if (tenantIds.length === 0) return [];
    const documents = await this.model.find({ tenantId: { $in: tenantIds as string[] } }).exec();
    return documents.map((document) => toRecord(document));
  }

  async search(filter: {
    readonly planKey?: SubscriptionPlanKey;
    readonly status?: TenantSubscriptionStatus;
  }): Promise<readonly TenantSubscriptionRecord[]> {
    const query: Record<string, unknown> = {};
    if (filter.planKey) query.planKey = filter.planKey;
    if (filter.status) query.status = filter.status;
    const documents = await this.model.find(query).exec();
    return documents.map((document) => toRecord(document));
  }

  async countAllGroupedByPlanKey(): Promise<Readonly<Record<string, number>>> {
    const rows = await this.model.aggregate<{ _id: string; count: number }>([
      { $group: { _id: '$planKey', count: { $sum: 1 } } },
    ]);
    const result: Record<string, number> = {};
    for (const row of rows) result[row._id] = row.count;
    return result;
  }
}
