import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { BusinessTypeMongoose } from './business-type.mongoose.schema';
import type { BusinessTypeRecord } from './business-type.types';
import type { CreateBusinessTypeDto } from './dtos/create-business-type.dto';
import type { UpdateBusinessTypeDto } from './dtos/update-business-type.dto';

const DEFAULT_TERMINOLOGY = {
  customerLabel: 'Customer',
  orderLabel: 'Order',
  itemLabel: 'Item',
  deliveryLabel: 'Delivery',
};

function toRecord(document: BusinessTypeMongoose & { _id: Types.ObjectId }): BusinessTypeRecord {
  return {
    id: document._id.toString(),
    value: document.value,
    label: document.label,
    description: document.description,
    isActive: document.isActive,
    defaultTerminology: { ...DEFAULT_TERMINOLOGY, ...document.defaultTerminology },
    defaultOrderStatuses: document.defaultOrderStatuses ?? [],
    defaultServices: document.defaultServices ?? [],
    defaultItemCategories: document.defaultItemCategories ?? [],
    defaultExpenseCategories: document.defaultExpenseCategories ?? [],
    createdAt: (document as unknown as { createdAt: Date }).createdAt,
    updatedAt: (document as unknown as { updatedAt: Date }).updatedAt,
  };
}

@Injectable()
export class BusinessTypeService {
  constructor(
    @InjectModel(BusinessTypeMongoose.name)
    private readonly model: Model<BusinessTypeMongoose>,
  ) {}

  async list(): Promise<readonly BusinessTypeRecord[]> {
    const documents = await this.model.find().sort({ label: 1 }).exec();
    return documents.map((document) =>
      toRecord(document as BusinessTypeMongoose & { _id: Types.ObjectId }),
    );
  }

  async findById(id: string): Promise<BusinessTypeRecord> {
    if (!Types.ObjectId.isValid(id)) throw new NotFoundException('Business type not found');
    const document = await this.model.findById(id).exec();
    if (!document) throw new NotFoundException('Business type not found');
    return toRecord(document);
  }

  async create(input: CreateBusinessTypeDto): Promise<BusinessTypeRecord> {
    const existing = await this.model.findOne({ value: input.value }).exec();
    if (existing) throw new ConflictException('This business type is already configured');

    const document = await this.model.create({
      value: input.value,
      label: input.label,
      description: input.description,
      isActive: input.isActive ?? true,
      defaultTerminology: { ...DEFAULT_TERMINOLOGY, ...input.defaultTerminology },
      defaultOrderStatuses: input.defaultOrderStatuses ?? [],
      defaultServices: input.defaultServices ?? [],
      defaultItemCategories: input.defaultItemCategories ?? [],
      defaultExpenseCategories: input.defaultExpenseCategories ?? [],
    });
    return toRecord(document);
  }

  async update(id: string, input: UpdateBusinessTypeDto): Promise<BusinessTypeRecord> {
    if (!Types.ObjectId.isValid(id)) throw new NotFoundException('Business type not found');
    const document = await this.model.findByIdAndUpdate(id, { $set: input }, { new: true }).exec();
    if (!document) throw new NotFoundException('Business type not found');
    return toRecord(document);
  }

  async remove(id: string): Promise<void> {
    if (!Types.ObjectId.isValid(id)) throw new NotFoundException('Business type not found');
    const result = await this.model.findByIdAndDelete(id).exec();
    if (!result) throw new NotFoundException('Business type not found');
  }
}
