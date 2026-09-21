import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { BillingAttemptMongoose } from './billing-attempt.mongoose.schema';
import {
  BillingAttemptStatus,
  type BillingAttemptRecord,
  type BillingAttemptRepository,
  type CreateBillingAttemptInput,
} from './billing.types';

function toRecord(
  document: BillingAttemptMongoose & { _id: Types.ObjectId },
): BillingAttemptRecord {
  return {
    id: document._id.toString(),
    tenantId: document.tenantId,
    razorpayOrderId: document.razorpayOrderId,
    razorpayPaymentId: document.razorpayPaymentId,
    amountInPaise: document.amountInPaise,
    currency: document.currency,
    billingCycle: document.billingCycle,
    planKeyAtCreation: document.planKeyAtCreation,
    status: document.status,
    createdAt: (document as unknown as { createdAt: Date }).createdAt,
    updatedAt: (document as unknown as { updatedAt: Date }).updatedAt,
  };
}

@Injectable()
export class MongoBillingAttemptRepository implements BillingAttemptRepository {
  constructor(
    @InjectModel(BillingAttemptMongoose.name)
    private readonly model: Model<BillingAttemptMongoose>,
  ) {}

  async create(input: CreateBillingAttemptInput): Promise<BillingAttemptRecord> {
    const document = await this.model.create({ ...input, status: BillingAttemptStatus.CREATED });
    return toRecord(document);
  }

  async findByRazorpayOrderId(razorpayOrderId: string): Promise<BillingAttemptRecord | null> {
    const document = await this.model.findOne({ razorpayOrderId }).exec();
    return document ? toRecord(document) : null;
  }

  async markPaid(id: string, razorpayPaymentId: string): Promise<void> {
    if (!Types.ObjectId.isValid(id)) return;
    await this.model
      .updateOne({ _id: id }, { $set: { status: BillingAttemptStatus.PAID, razorpayPaymentId } })
      .exec();
  }

  async markFailed(id: string): Promise<void> {
    if (!Types.ObjectId.isValid(id)) return;
    await this.model
      .updateOne({ _id: id }, { $set: { status: BillingAttemptStatus.FAILED } })
      .exec();
  }

  async listByTenantId(tenantId: string): Promise<readonly BillingAttemptRecord[]> {
    const documents = await this.model.find({ tenantId }).sort({ createdAt: -1 }).exec();
    return documents.map((document) => toRecord(document));
  }
}
