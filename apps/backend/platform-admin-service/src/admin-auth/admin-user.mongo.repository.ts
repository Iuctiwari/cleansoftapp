import { InjectModel } from '@nestjs/mongoose';
import { Injectable } from '@nestjs/common';
import { Model, Types } from 'mongoose';

import { AdminUserMongoose } from './admin-user.mongoose.schema';
import type { AdminUserRecord, AdminUserRepository } from './admin-auth.types';

function toRecord(document: AdminUserMongoose & { _id: Types.ObjectId }): AdminUserRecord {
  return {
    id: document._id.toString(),
    email: document.email,
    passwordHash: document.passwordHash,
    role: document.role,
    isActive: document.isActive,
    lastLoginAt: document.lastLoginAt,
    createdAt: (document as unknown as { createdAt: Date }).createdAt,
    updatedAt: (document as unknown as { updatedAt: Date }).updatedAt,
  };
}

@Injectable()
export class MongoAdminUserRepository implements AdminUserRepository {
  constructor(
    @InjectModel(AdminUserMongoose.name)
    private readonly model: Model<AdminUserMongoose>,
  ) {}

  async findByEmail(email: string): Promise<AdminUserRecord | null> {
    const document = await this.model
      .findOne({ email: email.trim().toLowerCase() })
      .select('+passwordHash')
      .exec();
    if (!document) return null;
    return toRecord(document);
  }

  async findById(id: string): Promise<AdminUserRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const document = await this.model.findById(id).select('+passwordHash').exec();
    if (!document) return null;
    return toRecord(document);
  }

  async updateLastLogin(id: string, when: Date): Promise<void> {
    if (!Types.ObjectId.isValid(id)) return;
    await this.model.updateOne({ _id: id }, { $set: { lastLoginAt: when } }).exec();
  }
}
