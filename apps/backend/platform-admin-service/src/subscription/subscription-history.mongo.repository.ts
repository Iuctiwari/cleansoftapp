import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { SubscriptionHistoryMongoose } from './subscription-history.mongoose.schema';
import type {
  SubscriptionHistoryRecord,
  SubscriptionHistoryRepository,
} from './subscription.types';

interface MongoDuplicateKeyError {
  readonly code?: number;
}

function isDuplicateKeyError(error: unknown): boolean {
  return (
    typeof error === 'object' && error !== null && (error as MongoDuplicateKeyError).code === 11000
  );
}

function toRecord(
  document: SubscriptionHistoryMongoose & { _id: Types.ObjectId },
): SubscriptionHistoryRecord {
  return {
    id: document._id.toString(),
    tenantId: document.tenantId,
    action: document.action,
    previousValue: document.previousValue,
    newValue: document.newValue,
    actorAdminUserId: document.actorAdminUserId,
    reason: document.reason,
    razorpayEventId: document.razorpayEventId,
    timestamp: document.timestamp,
  };
}

@Injectable()
export class MongoSubscriptionHistoryRepository implements SubscriptionHistoryRepository {
  constructor(
    @InjectModel(SubscriptionHistoryMongoose.name)
    private readonly model: Model<SubscriptionHistoryMongoose>,
  ) {}

  async append(
    entry: Omit<SubscriptionHistoryRecord, 'id' | 'timestamp'>,
  ): Promise<SubscriptionHistoryRecord> {
    const document = await this.model.create({ ...entry, timestamp: new Date() });
    return toRecord(document);
  }

  async listByTenantId(tenantId: string): Promise<readonly SubscriptionHistoryRecord[]> {
    const documents = await this.model.find({ tenantId }).sort({ timestamp: -1 }).exec();
    return documents.map((document) => toRecord(document));
  }

  async appendIfEventNotProcessed(
    entry: Omit<SubscriptionHistoryRecord, 'id' | 'timestamp' | 'razorpayEventId'>,
    razorpayEventId: string,
  ): Promise<SubscriptionHistoryRecord | null> {
    try {
      const document = await this.model.create({
        ...entry,
        razorpayEventId,
        timestamp: new Date(),
      });
      return toRecord(document);
    } catch (error) {
      if (isDuplicateKeyError(error)) return null;
      throw error;
    }
  }
}
