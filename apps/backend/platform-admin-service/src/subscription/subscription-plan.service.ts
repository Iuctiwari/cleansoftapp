import { ConflictException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { SubscriptionPlanMongoose } from './subscription-plan.mongoose.schema';
import {
  TENANT_SUBSCRIPTION_REPOSITORY,
  type SubscriptionPlanRecord,
  type TenantSubscriptionRepository,
} from './subscription.types';
import type { CreateSubscriptionPlanDto } from './dtos/create-subscription-plan.dto';
import type { UpdateSubscriptionPlanDto } from './dtos/update-subscription-plan.dto';

function toRecord(
  document: SubscriptionPlanMongoose & { _id: Types.ObjectId },
): SubscriptionPlanRecord {
  return {
    id: document._id.toString(),
    planKey: document.planKey,
    displayName: document.displayName,
    monthlyPriceInPaise: document.monthlyPriceInPaise,
    annualPriceInPaise: document.annualPriceInPaise,
    maxBranches: document.maxBranches,
    maxStaff: document.maxStaff,
    maxMonthlyOrders: document.maxMonthlyOrders,
    trialDays: document.trialDays,
    includedModuleKeys: document.includedModuleKeys,
    isActive: document.isActive,
    createdAt: (document as unknown as { createdAt: Date }).createdAt,
    updatedAt: (document as unknown as { updatedAt: Date }).updatedAt,
  };
}

@Injectable()
export class SubscriptionPlanService {
  constructor(
    @InjectModel(SubscriptionPlanMongoose.name)
    private readonly model: Model<SubscriptionPlanMongoose>,
    @Inject(TENANT_SUBSCRIPTION_REPOSITORY)
    private readonly tenantSubscriptions: TenantSubscriptionRepository,
  ) {}

  async list(): Promise<readonly SubscriptionPlanRecord[]> {
    const documents = await this.model.find().sort({ monthlyPriceInPaise: 1 }).exec();
    return documents.map((document) => toRecord(document));
  }

  async findByPlanKey(planKey: string): Promise<SubscriptionPlanRecord> {
    const document = await this.model.findOne({ planKey }).exec();
    if (!document) throw new NotFoundException('Subscription plan not found');
    return toRecord(document);
  }

  async create(input: CreateSubscriptionPlanDto): Promise<SubscriptionPlanRecord> {
    const existing = await this.model.findOne({ planKey: input.planKey }).exec();
    if (existing) throw new ConflictException('This plan key is already configured');

    const document = await this.model.create({
      ...input,
      trialDays: input.trialDays ?? 0,
      includedModuleKeys: input.includedModuleKeys ?? [],
      isActive: input.isActive ?? true,
    });
    return toRecord(document);
  }

  async update(planKey: string, input: UpdateSubscriptionPlanDto): Promise<SubscriptionPlanRecord> {
    const document = await this.model
      .findOneAndUpdate({ planKey }, { $set: input }, { new: true })
      .exec();
    if (!document) throw new NotFoundException('Subscription plan not found');
    return toRecord(document);
  }

  async remove(planKey: string): Promise<void> {
    const assigned = await this.tenantSubscriptions.search({
      planKey: planKey as SubscriptionPlanRecord['planKey'],
    });
    if (assigned.length > 0) {
      throw new ConflictException(
        `Cannot delete this plan — ${assigned.length} tenant(s) are currently assigned to it. Reassign them to another plan first.`,
      );
    }
    const result = await this.model.deleteOne({ planKey }).exec();
    if (result.deletedCount === 0) throw new NotFoundException('Subscription plan not found');
  }

  async tenantCountsByPlan(): Promise<Readonly<Record<string, number>>> {
    return this.tenantSubscriptions.countAllGroupedByPlanKey();
  }
}
