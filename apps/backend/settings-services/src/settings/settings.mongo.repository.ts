import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';

import { CatalogStatus, PricingType, UnitType } from './enums';
import {
  SettingsItemCategoryMongoose,
  SettingsServiceCategoryMongoose,
  SettingsServiceMappingMongoose,
  SettingsServiceMongoose,
  SettingsServicePricingMongoose,
} from './settings.schema';
import type {
  SettingsCategoryRecord,
  SettingsItemRecord,
  SettingsListQuery,
  SettingsMappingRecord,
  SettingsPricingRecord,
  SettingsRepository,
  SettingsScope,
  SettingsServiceRecord,
} from './settings.types';

@Injectable()
export class MongoSettingsRepository implements SettingsRepository {
  constructor(
    @InjectModel(SettingsServiceCategoryMongoose.name)
    private readonly serviceCategoryModel: Model<SettingsServiceCategoryMongoose>,
    @InjectModel(SettingsItemCategoryMongoose.name)
    private readonly itemCategoryModel: Model<SettingsItemCategoryMongoose>,
    @InjectModel(SettingsServiceMongoose.name)
    private readonly serviceModel: Model<SettingsServiceMongoose>,
    @InjectModel(SettingsServiceMappingMongoose.name)
    private readonly serviceMappingModel: Model<SettingsServiceMappingMongoose>,
    @InjectModel(SettingsServicePricingMongoose.name)
    private readonly servicePricingModel: Model<SettingsServicePricingMongoose>,
  ) {}

  // ─────────────────────────────────────────────────────────────────────────────
  // SERVICES
  // ─────────────────────────────────────────────────────────────────────────────
  async listServices(
    scope: SettingsScope,
    query?: SettingsListQuery,
  ): Promise<readonly SettingsServiceRecord[]> {
    const filter: Record<string, unknown> = { tenantId: scope.tenantId };
    if (query?.status) filter.status = query.status;
    if (query?.search) {
      filter.$or = [
        { serviceName: { $regex: query.search, $options: 'i' } },
        { code: { $regex: query.search, $options: 'i' } },
      ];
    }
    if (query?.branchId) {
      filter.$or = [{ branchIds: query.branchId }, { branchIds: { $size: 0 } }];
    }

    const docs = await this.serviceModel.find(filter).sort({ serviceName: 1 }).lean().exec();
    return docs.map((doc) => this.mapService(doc));
  }

  async findService(scope: SettingsScope, id: string): Promise<SettingsServiceRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const doc = await this.serviceModel
      .findOne({ _id: new Types.ObjectId(id), tenantId: scope.tenantId })
      .lean()
      .exec();
    return doc ? this.mapService(doc) : null;
  }

  async findServiceByCode(
    scope: SettingsScope,
    code: string,
  ): Promise<SettingsServiceRecord | null> {
    const doc = await this.serviceModel
      .findOne({ code: code.toUpperCase().trim(), tenantId: scope.tenantId })
      .lean()
      .exec();
    return doc ? this.mapService(doc) : null;
  }

  async createService(
    scope: SettingsScope,
    input: Record<string, unknown>,
  ): Promise<SettingsServiceRecord> {
    const created = await this.serviceModel.create({
      ...input,
      tenantId: scope.tenantId,
      createdBy: scope.actorId,
      updatedBy: scope.actorId,
    });
    return this.mapService(created.toObject());
  }

  async updateService(
    scope: SettingsScope,
    id: string,
    input: Record<string, unknown>,
  ): Promise<SettingsServiceRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const updated = await this.serviceModel
      .findOneAndUpdate(
        { _id: new Types.ObjectId(id), tenantId: scope.tenantId },
        { $set: { ...input, updatedBy: scope.actorId } },
        { new: true },
      )
      .lean()
      .exec();
    return updated ? this.mapService(updated) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ITEMS
  // ─────────────────────────────────────────────────────────────────────────────
  async listItems(
    scope: SettingsScope,
    query?: SettingsListQuery,
  ): Promise<readonly SettingsItemRecord[]> {
    const filter: Record<string, unknown> = { tenantId: scope.tenantId };
    if (query?.status) filter.status = query.status;
    if (query?.search) {
      filter.$or = [
        { name: { $regex: query.search, $options: 'i' } },
        { code: { $regex: query.search, $options: 'i' } },
      ];
    }
    if (query?.branchId) {
      filter.$or = [{ branchIds: query.branchId }, { branchIds: { $size: 0 } }];
    }

    const docs = await this.itemCategoryModel.find(filter).sort({ name: 1 }).lean().exec();
    return docs.map((doc) => this.mapItem(doc));
  }

  async findItem(scope: SettingsScope, id: string): Promise<SettingsItemRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const doc = await this.itemCategoryModel
      .findOne({ _id: new Types.ObjectId(id), tenantId: scope.tenantId })
      .lean()
      .exec();
    return doc ? this.mapItem(doc) : null;
  }

  async findItemByCode(scope: SettingsScope, code: string): Promise<SettingsItemRecord | null> {
    const doc = await this.itemCategoryModel
      .findOne({ code: code.toUpperCase().trim(), tenantId: scope.tenantId })
      .lean()
      .exec();
    return doc ? this.mapItem(doc) : null;
  }

  async createItem(
    scope: SettingsScope,
    input: Record<string, unknown>,
  ): Promise<SettingsItemRecord> {
    const created = await this.itemCategoryModel.create({
      ...input,
      tenantId: scope.tenantId,
      createdBy: scope.actorId,
      updatedBy: scope.actorId,
    });
    return this.mapItem(created.toObject());
  }

  async updateItem(
    scope: SettingsScope,
    id: string,
    input: Record<string, unknown>,
  ): Promise<SettingsItemRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const updated = await this.itemCategoryModel
      .findOneAndUpdate(
        { _id: new Types.ObjectId(id), tenantId: scope.tenantId },
        { $set: { ...input, updatedBy: scope.actorId } },
        { new: true },
      )
      .lean()
      .exec();
    return updated ? this.mapItem(updated) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────────────────
  async listCategories(
    scope: SettingsScope,
    query?: SettingsListQuery,
  ): Promise<readonly SettingsCategoryRecord[]> {
    const filter: Record<string, unknown> = { tenantId: scope.tenantId };
    if (query?.status) filter.status = query.status;
    if (query?.search) {
      filter.$or = [
        { name: { $regex: query.search, $options: 'i' } },
        { code: { $regex: query.search, $options: 'i' } },
      ];
    }
    if (query?.branchId) {
      filter.$or = [{ branchIds: query.branchId }, { branchIds: { $size: 0 } }];
    }

    const docs = await this.serviceCategoryModel.find(filter).sort({ name: 1 }).lean().exec();
    return docs.map((doc) => this.mapCategory(doc));
  }

  async findCategory(scope: SettingsScope, id: string): Promise<SettingsCategoryRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const doc = await this.serviceCategoryModel
      .findOne({ _id: new Types.ObjectId(id), tenantId: scope.tenantId })
      .lean()
      .exec();
    return doc ? this.mapCategory(doc) : null;
  }

  async findCategoryByCode(
    scope: SettingsScope,
    code: string,
  ): Promise<SettingsCategoryRecord | null> {
    const doc = await this.serviceCategoryModel
      .findOne({ code: code.toUpperCase().trim(), tenantId: scope.tenantId })
      .lean()
      .exec();
    return doc ? this.mapCategory(doc) : null;
  }

  async createCategory(
    scope: SettingsScope,
    input: Record<string, unknown>,
  ): Promise<SettingsCategoryRecord> {
    const created = await this.serviceCategoryModel.create({
      ...input,
      tenantId: scope.tenantId,
      createdBy: scope.actorId,
      updatedBy: scope.actorId,
    });
    return this.mapCategory(created.toObject());
  }

  async updateCategory(
    scope: SettingsScope,
    id: string,
    input: Record<string, unknown>,
  ): Promise<SettingsCategoryRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const updated = await this.serviceCategoryModel
      .findOneAndUpdate(
        { _id: new Types.ObjectId(id), tenantId: scope.tenantId },
        { $set: { ...input, updatedBy: scope.actorId } },
        { new: true },
      )
      .lean()
      .exec();
    return updated ? this.mapCategory(updated) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PRICING & MAPPINGS
  // ─────────────────────────────────────────────────────────────────────────────
  async listPricing(
    scope: SettingsScope,
    filters?: {
      serviceId?: string;
      itemCategoryId?: string;
      branchId?: string;
      status?: CatalogStatus;
    },
  ): Promise<readonly SettingsPricingRecord[]> {
    const filter: Record<string, unknown> = { tenantId: scope.tenantId };
    if (filters?.serviceId && Types.ObjectId.isValid(filters.serviceId)) {
      filter.serviceId = new Types.ObjectId(filters.serviceId);
    }
    if (filters?.itemCategoryId && Types.ObjectId.isValid(filters.itemCategoryId)) {
      filter.itemCategoryId = new Types.ObjectId(filters.itemCategoryId);
    }
    if (filters?.branchId !== undefined) {
      filter.branchId = filters.branchId;
    }
    if (filters?.status !== undefined) {
      filter.status = filters.status;
    }

    const docs = await this.servicePricingModel
      .find(filter)
      .sort({ effectiveFrom: -1 })
      .lean()
      .exec();
    return docs.map((doc) => this.mapPricing(doc));
  }

  async findPricing(scope: SettingsScope, id: string): Promise<SettingsPricingRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const doc = await this.servicePricingModel
      .findOne({ _id: new Types.ObjectId(id), tenantId: scope.tenantId })
      .lean()
      .exec();
    return doc ? this.mapPricing(doc) : null;
  }

  async createPricing(
    scope: SettingsScope,
    input: Record<string, unknown>,
  ): Promise<SettingsPricingRecord> {
    const created = await this.servicePricingModel.create({
      ...input,
      serviceId: new Types.ObjectId(input.serviceId as string),
      itemCategoryId: new Types.ObjectId(input.itemCategoryId as string),
      tenantId: scope.tenantId,
      createdBy: scope.actorId,
      updatedBy: scope.actorId,
    });
    return this.mapPricing(created.toObject());
  }

  async updatePricing(
    scope: SettingsScope,
    id: string,
    input: Record<string, unknown>,
  ): Promise<SettingsPricingRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const updated = await this.servicePricingModel
      .findOneAndUpdate(
        { _id: new Types.ObjectId(id), tenantId: scope.tenantId },
        { $set: { ...input, updatedBy: scope.actorId } },
        { new: true },
      )
      .lean()
      .exec();
    return updated ? this.mapPricing(updated) : null;
  }

  async listMappings(
    scope: SettingsScope,
    filters?: {
      serviceId?: string;
      itemCategoryId?: string;
      branchId?: string;
      status?: CatalogStatus;
    },
  ): Promise<readonly SettingsMappingRecord[]> {
    const filter: Record<string, unknown> = { tenantId: scope.tenantId };
    if (filters?.serviceId && Types.ObjectId.isValid(filters.serviceId)) {
      filter.serviceId = new Types.ObjectId(filters.serviceId);
    }
    if (filters?.itemCategoryId && Types.ObjectId.isValid(filters.itemCategoryId)) {
      filter.itemCategoryId = new Types.ObjectId(filters.itemCategoryId);
    }
    if (filters?.branchId !== undefined) {
      filter.branchId = filters.branchId;
    }
    if (filters?.status !== undefined) {
      filter.status = filters.status;
    }

    const docs = await this.serviceMappingModel.find(filter).lean().exec();
    return docs.map((doc) => this.mapMapping(doc));
  }

  async createMapping(
    scope: SettingsScope,
    input: Record<string, unknown>,
  ): Promise<SettingsMappingRecord> {
    const created = await this.serviceMappingModel.create({
      ...input,
      serviceId: new Types.ObjectId(input.serviceId as string),
      itemCategoryId: new Types.ObjectId(input.itemCategoryId as string),
      tenantId: scope.tenantId,
      createdBy: scope.actorId,
      updatedBy: scope.actorId,
    });
    return this.mapMapping(created.toObject());
  }

  async updateMapping(
    scope: SettingsScope,
    id: string,
    input: Record<string, unknown>,
  ): Promise<SettingsMappingRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const updated = await this.serviceMappingModel
      .findOneAndUpdate(
        { _id: new Types.ObjectId(id), tenantId: scope.tenantId },
        { $set: { ...input, updatedBy: scope.actorId } },
        { new: true },
      )
      .lean()
      .exec();
    return updated ? this.mapMapping(updated) : null;
  }

  async findMapping(
    scope: SettingsScope,
    serviceId: string,
    itemCategoryId: string,
    branchId?: string | null,
  ): Promise<SettingsMappingRecord | null> {
    if (!Types.ObjectId.isValid(serviceId) || !Types.ObjectId.isValid(itemCategoryId)) return null;
    const doc = await this.serviceMappingModel
      .findOne({
        serviceId: new Types.ObjectId(serviceId),
        itemCategoryId: new Types.ObjectId(itemCategoryId),
        branchId: branchId ?? null,
        tenantId: scope.tenantId,
      })
      .lean()
      .exec();
    return doc ? this.mapMapping(doc) : null;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // MAPPERS
  // ─────────────────────────────────────────────────────────────────────────────
  private mapService(raw: object): SettingsServiceRecord {
    const doc = raw as Record<string, unknown>;
    return {
      id: this.identifier(doc._id) ?? '',
      tenantId: String(doc.tenantId),
      serviceName: String(doc.serviceName),
      name: String(doc.serviceName),
      code: String(doc.code),
      pricingType: doc.pricingType as PricingType,
      description: this.text(doc.description),
      categoryId: this.identifier(doc.categoryId),
      estimatedTimeMins:
        doc.estimatedTimeMins !== undefined ? Number(doc.estimatedTimeMins) : undefined,
      branchIds: Array.isArray(doc.branchIds) ? doc.branchIds.map(String) : [],
      status: doc.status as CatalogStatus,
      createdAt: doc.createdAt as Date,
      updatedAt: doc.updatedAt as Date,
      version: typeof doc.__v === 'number' ? doc.__v : 1,
    };
  }

  private mapItem(raw: object): SettingsItemRecord {
    const doc = raw as Record<string, unknown>;
    return {
      id: this.identifier(doc._id) ?? '',
      tenantId: String(doc.tenantId),
      name: String(doc.name),
      code: String(doc.code),
      description: this.text(doc.description),
      category: this.text(doc.category),
      catalogGroupCodes: Array.isArray(doc.catalogGroupCodes)
        ? doc.catalogGroupCodes.map(String)
        : [],
      unitType: doc.unitType as UnitType,
      branchIds: Array.isArray(doc.branchIds) ? doc.branchIds.map(String) : [],
      status: doc.status as CatalogStatus,
      createdAt: doc.createdAt as Date,
      updatedAt: doc.updatedAt as Date,
      version: typeof doc.__v === 'number' ? doc.__v : 1,
    };
  }

  private mapCategory(raw: object): SettingsCategoryRecord {
    const doc = raw as Record<string, unknown>;
    return {
      id: this.identifier(doc._id) ?? '',
      tenantId: String(doc.tenantId),
      name: String(doc.name),
      code: String(doc.code),
      description: this.text(doc.description),
      branchIds: Array.isArray(doc.branchIds) ? doc.branchIds.map(String) : [],
      status: doc.status as CatalogStatus,
      createdAt: doc.createdAt as Date,
      updatedAt: doc.updatedAt as Date,
      version: typeof doc.__v === 'number' ? doc.__v : 1,
    };
  }

  private mapMapping(raw: object): SettingsMappingRecord {
    const doc = raw as Record<string, unknown>;
    return {
      id: this.identifier(doc._id) ?? '',
      tenantId: String(doc.tenantId),
      itemCategoryId: this.identifier(doc.itemCategoryId) ?? '',
      serviceId: this.identifier(doc.serviceId) ?? '',
      branchId: this.text(doc.branchId) ?? null,
      pricingType: doc.pricingType as PricingType,
      requiresPricingConfiguration: Boolean(doc.requiresPricingConfiguration),
      status: doc.status as CatalogStatus,
      createdAt: doc.createdAt as Date,
      updatedAt: doc.updatedAt as Date,
      version: typeof doc.__v === 'number' ? doc.__v : 1,
    };
  }

  private mapPricing(raw: object): SettingsPricingRecord {
    const doc = raw as Record<string, unknown>;
    return {
      id: this.identifier(doc._id) ?? '',
      tenantId: String(doc.tenantId),
      serviceId: this.identifier(doc.serviceId) ?? '',
      itemCategoryId: this.identifier(doc.itemCategoryId) ?? '',
      branchId: this.text(doc.branchId) ?? null,
      pricingType: doc.pricingType as PricingType,
      basePrice: Number(doc.basePrice),
      taxPct: Number(doc.taxPct ?? 0),
      effectiveFrom: doc.effectiveFrom as Date,
      effectiveTo: doc.effectiveTo ? (doc.effectiveTo as Date) : undefined,
      status: doc.status as CatalogStatus,
      createdAt: doc.createdAt as Date,
      updatedAt: doc.updatedAt as Date,
      version: typeof doc.__v === 'number' ? doc.__v : 1,
    };
  }

  private identifier(value: unknown): string | undefined {
    if (typeof value === 'string') return value;
    if (value instanceof Types.ObjectId) return value.toHexString();
    if (value && typeof value === 'object' && '_id' in value) {
      return String(value._id);
    }
    return undefined;
  }

  private text(value: unknown): string | undefined {
    return typeof value === 'string' ? value : undefined;
  }
}
