import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { ThemeHistoryMongoose } from './theme-history.mongoose.schema';
import type { ThemeHistoryRecord, ThemeHistoryRepository } from './theme.types';

function toRecord(document: ThemeHistoryMongoose & { _id: Types.ObjectId }): ThemeHistoryRecord {
  return {
    id: document._id.toString(),
    tenantId: document.tenantId,
    action: document.action,
    previousValue: document.previousValue,
    newValue: document.newValue,
    actorAdminUserId: document.actorAdminUserId,
    timestamp: document.timestamp,
  };
}

@Injectable()
export class MongoThemeHistoryRepository implements ThemeHistoryRepository {
  constructor(
    @InjectModel(ThemeHistoryMongoose.name)
    private readonly model: Model<ThemeHistoryMongoose>,
  ) {}

  async append(entry: Omit<ThemeHistoryRecord, 'id' | 'timestamp'>): Promise<ThemeHistoryRecord> {
    const document = await this.model.create({ ...entry, timestamp: new Date() });
    return toRecord(document);
  }

  async listByTenantId(tenantId: string): Promise<readonly ThemeHistoryRecord[]> {
    const documents = await this.model.find({ tenantId }).sort({ timestamp: -1 }).exec();
    return documents.map((document) => toRecord(document));
  }
}
