import { Injectable } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { createActiveTenantFilter, createAuditFields } from '@nexoraa/database';
import { Types, type Connection, type Model } from 'mongoose';

import {
  CatalogTemplateMongoose,
  ItemCategoryMongoose,
  ServiceCategoryMongoose,
  ServiceMappingMongoose,
  ServiceMongoose,
  ServicePricingMongoose,
} from './catalog.schema';
import type {
  CatalogBusinessType,
  CatalogListQuery,
  CatalogPage,
  CatalogRepository,
  CatalogScope,
  CatalogTemplateRecord,
  ItemCategoryRecord,
  ServiceCategoryRecord,
  ServiceMappingRecord,
  ServicePricingRecord,
  ServiceRecord,
} from './catalog.types';
import { CatalogStatus, type PricingType, type UnitType } from './enums';

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

@Injectable()
export class MongoCatalogRepository implements CatalogRepository {
  constructor(
    @InjectConnection() private readonly connection: Connection,
    @InjectModel(CatalogTemplateMongoose.name)
    private readonly templateModel: Model<CatalogTemplateMongoose>,
    @InjectModel(ItemCategoryMongoose.name) private readonly itemModel: Model<ItemCategoryMongoose>,
    @InjectModel(ServiceMongoose.name) private readonly serviceModel: Model<ServiceMongoose>,
    @InjectModel(ServiceCategoryMongoose.name)
    private readonly serviceCategoryModel: Model<ServiceCategoryMongoose>,
    @InjectModel(ServiceMappingMongoose.name)
    private readonly mappingModel: Model<ServiceMappingMongoose>,
    @InjectModel(ServicePricingMongoose.name)
    private readonly pricingModel: Model<ServicePricingMongoose>,
  ) {}

  async listTemplatesByBusinessTypes(
    businessTypes: readonly CatalogBusinessType[],
  ): Promise<readonly CatalogTemplateRecord[]> {
    if (businessTypes.length === 0) return [];
    const documents = await this.templateModel
      .find({ businessType: { $in: [...new Set(businessTypes)] }, status: CatalogStatus.ACTIVE })
      .sort({ businessType: 1 })
      .lean()
      .exec();
    return documents.map((document) => this.mapTemplate(document));
  }

  async upsertTemplate(template: CatalogTemplateRecord): Promise<void> {
    await this.templateModel
      .updateOne(
        { code: template.code },
        {
          $set: {
            businessType: template.businessType,
            name: template.name,
            status: template.status,
            templateVersion: template.templateVersion,
            items: template.items,
            services: template.services,
            mappings: template.mappings,
            pricing: template.pricing,
          },
        },
        { runValidators: true, upsert: true },
      )
      .exec();
  }

  async createItemCategory(scope: CatalogScope, input: object): Promise<ItemCategoryRecord> {
    const document = await this.itemModel.create(this.createFields(scope, input));
    return this.mapItem(document.toObject() as unknown as Record<string, unknown>);
  }

  async findItemCategoryByCode(
    scope: CatalogScope,
    code: string,
  ): Promise<ItemCategoryRecord | null> {
    const document = await this.itemModel
      .findOne({ tenantId: new Types.ObjectId(scope.tenantId), code: code.trim().toUpperCase() })
      .lean()
      .exec();
    return document ? this.mapItem(document) : null;
  }

  async findItemCategory(scope: CatalogScope, id: string): Promise<ItemCategoryRecord | null> {
    const document = await this.findOne(this.itemModel, scope, id);
    return document ? this.mapItem(document) : null;
  }

  async listItemCategories(
    scope: CatalogScope,
    query: CatalogListQuery,
  ): Promise<CatalogPage<ItemCategoryRecord>> {
    const result = await this.listModel(this.itemModel, scope, query, 'name');
    return { ...result, items: result.items.map((item) => this.mapItem(item)) };
  }

  async updateItemCategory(
    scope: CatalogScope,
    id: string,
    input: object,
  ): Promise<ItemCategoryRecord | null> {
    const document = await this.updateOne(this.itemModel, scope, id, input);
    return document ? this.mapItem(document) : null;
  }

  async createService(scope: CatalogScope, input: object): Promise<ServiceRecord> {
    const document = await this.serviceModel.create(this.createFields(scope, input));
    return this.mapService(document.toObject() as unknown as Record<string, unknown>);
  }

  async findServiceByCode(scope: CatalogScope, code: string): Promise<ServiceRecord | null> {
    const document = await this.serviceModel
      .findOne({ tenantId: new Types.ObjectId(scope.tenantId), code: code.trim().toUpperCase() })
      .lean()
      .exec();
    return document ? this.mapService(document) : null;
  }

  async findService(scope: CatalogScope, id: string): Promise<ServiceRecord | null> {
    const document = await this.findOne(this.serviceModel, scope, id);
    return document ? this.mapService(document) : null;
  }

  async listServices(
    scope: CatalogScope,
    query: CatalogListQuery & { categoryId?: string },
  ): Promise<CatalogPage<ServiceRecord>> {
    const extra = query.categoryId ? { categoryId: new Types.ObjectId(query.categoryId) } : {};
    const result = await this.listModel(this.serviceModel, scope, query, 'serviceName', extra);
    return { ...result, items: result.items.map((item) => this.mapService(item)) };
  }

  async updateService(
    scope: CatalogScope,
    id: string,
    input: object,
  ): Promise<ServiceRecord | null> {
    const document = await this.updateOne(this.serviceModel, scope, id, input);
    return document ? this.mapService(document) : null;
  }

  async createServiceCategory(scope: CatalogScope, input: object): Promise<ServiceCategoryRecord> {
    const document = await this.serviceCategoryModel.create(this.createFields(scope, input));
    return this.mapServiceCategory(document.toObject() as unknown as Record<string, unknown>);
  }

  async findServiceCategory(
    scope: CatalogScope,
    id: string,
  ): Promise<ServiceCategoryRecord | null> {
    const document = await this.findOne(this.serviceCategoryModel, scope, id);
    return document ? this.mapServiceCategory(document) : null;
  }

  async listServiceCategories(
    scope: CatalogScope,
    query: CatalogListQuery,
  ): Promise<CatalogPage<ServiceCategoryRecord>> {
    const result = await this.listModel(this.serviceCategoryModel, scope, query, 'name');
    return { ...result, items: result.items.map((item) => this.mapServiceCategory(item)) };
  }

  async updateServiceCategory(
    scope: CatalogScope,
    id: string,
    input: object,
  ): Promise<ServiceCategoryRecord | null> {
    const document = await this.updateOne(this.serviceCategoryModel, scope, id, input);
    return document ? this.mapServiceCategory(document) : null;
  }

  async createMapping(scope: CatalogScope, input: object): Promise<ServiceMappingRecord> {
    const document = await this.mappingModel.create(this.createFields(scope, input));
    return this.mapMapping(document.toObject() as unknown as Record<string, unknown>);
  }

  async findTenantWideMapping(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId: string,
  ): Promise<ServiceMappingRecord | null> {
    const document = await this.mappingModel
      .findOne({
        tenantId: new Types.ObjectId(scope.tenantId),
        serviceId: new Types.ObjectId(serviceId),
        itemCategoryId: new Types.ObjectId(itemCategoryId),
        branchId: null,
      })
      .lean()
      .exec();
    return document ? this.mapMapping(document) : null;
  }

  async findMapping(scope: CatalogScope, id: string): Promise<ServiceMappingRecord | null> {
    const document = await this.findOne(this.mappingModel, scope, id);
    return document ? this.mapMapping(document) : null;
  }

  async findEffectiveMapping(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId: string,
    branchId: string,
  ): Promise<ServiceMappingRecord | null> {
    const document = await this.mappingModel
      .findOne(
        createActiveTenantFilter(scope.tenantId, {
          serviceId: new Types.ObjectId(serviceId),
          itemCategoryId: new Types.ObjectId(itemCategoryId),
          status: CatalogStatus.ACTIVE,
          branchId: { $in: [branchId, null] },
        }),
      )
      .sort({ branchId: -1 })
      .lean()
      .exec();
    return document ? this.mapMapping(document) : null;
  }

  async listMappings(
    scope: CatalogScope,
    filters: {
      serviceId?: string;
      itemCategoryId?: string;
      branchId?: string;
      status?: CatalogStatus;
    },
  ): Promise<readonly ServiceMappingRecord[]> {
    const filter: Record<string, unknown> = createActiveTenantFilter(scope.tenantId);
    if (filters.serviceId) filter.serviceId = new Types.ObjectId(filters.serviceId);
    if (filters.itemCategoryId) filter.itemCategoryId = new Types.ObjectId(filters.itemCategoryId);
    if (filters.status) filter.status = filters.status;
    filter.branchId = { $in: [filters.branchId ?? scope.branchId, null] };
    const documents = await this.mappingModel.find(filter).sort({ createdAt: -1 }).lean().exec();
    return documents.map((document) =>
      this.mapMapping(document as unknown as Record<string, unknown>),
    );
  }

  async updateMapping(
    scope: CatalogScope,
    id: string,
    input: object,
  ): Promise<ServiceMappingRecord | null> {
    const document = await this.updateOne(this.mappingModel, scope, id, input);
    return document ? this.mapMapping(document) : null;
  }

  async createPricingIfNoOverlap(
    scope: CatalogScope,
    input: {
      serviceId: string;
      itemCategoryId: string;
      branchId: string | null;
      pricingType: PricingType;
      effectiveFrom: Date;
      effectiveTo?: Date;
      basePrice: number;
      taxPct: number;
      status: CatalogStatus;
    },
  ): Promise<ServicePricingRecord | null> {
    return this.connection.transaction(async (session) => {
      const service = await this.serviceModel
        .findOneAndUpdate(
          createActiveTenantFilter(scope.tenantId, { _id: input.serviceId }),
          {
            $currentDate: { updatedAt: true },
            $set: { updatedBy: new Types.ObjectId(scope.actorId) },
          },
          { new: true, session },
        )
        .exec();
      if (!service) return null;

      const overlap =
        input.status === CatalogStatus.ACTIVE
          ? await this.pricingModel
              .countDocuments(
                createActiveTenantFilter(scope.tenantId, {
                  serviceId: new Types.ObjectId(input.serviceId),
                  itemCategoryId: new Types.ObjectId(input.itemCategoryId),
                  branchId: input.branchId,
                  pricingType: input.pricingType,
                  status: CatalogStatus.ACTIVE,
                  effectiveFrom: {
                    $lt: input.effectiveTo ?? new Date(8_640_000_000_000_000),
                  },
                  $or: [{ effectiveTo: null }, { effectiveTo: { $gt: input.effectiveFrom } }],
                }),
              )
              .session(session)
              .exec()
          : 0;
      if (overlap > 0) return null;

      const [document] = await this.pricingModel.create([this.createFields(scope, input)], {
        session,
      });
      return this.mapPricing(document.toObject() as unknown as Record<string, unknown>);
    });
  }

  async findPricing(
    scope: CatalogScope,
    serviceId: string,
    pricingId: string,
  ): Promise<ServicePricingRecord | null> {
    if (!Types.ObjectId.isValid(pricingId)) return null;
    const document = await this.pricingModel
      .findOne(
        createActiveTenantFilter(scope.tenantId, {
          _id: pricingId,
          serviceId: new Types.ObjectId(serviceId),
          branchId: { $in: [scope.branchId, null] },
        }),
      )
      .lean()
      .exec();
    return document ? this.mapPricing(document) : null;
  }

  async updatePricingLifecycle(
    scope: CatalogScope,
    serviceId: string,
    pricingId: string,
    input: { effectiveTo?: Date; status?: CatalogStatus.INACTIVE },
  ): Promise<ServicePricingRecord | null> {
    const document = await this.pricingModel
      .findOneAndUpdate(
        createActiveTenantFilter(scope.tenantId, {
          _id: pricingId,
          serviceId: new Types.ObjectId(serviceId),
          branchId: { $in: [scope.branchId, null] },
        }),
        {
          $inc: { __v: 1 },
          $set: { ...input, updatedBy: new Types.ObjectId(scope.actorId) },
        },
        { new: true, runValidators: true },
      )
      .lean()
      .exec();
    return document ? this.mapPricing(document) : null;
  }

  async listPricing(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId?: string,
  ): Promise<readonly ServicePricingRecord[]> {
    const filter: Record<string, unknown> = createActiveTenantFilter(scope.tenantId, {
      serviceId: new Types.ObjectId(serviceId),
      branchId: { $in: [scope.branchId, null] },
    });
    if (itemCategoryId) filter.itemCategoryId = new Types.ObjectId(itemCategoryId);
    const documents = await this.pricingModel
      .find(filter)
      .sort({ effectiveFrom: -1 })
      .lean()
      .exec();
    return documents.map((document) =>
      this.mapPricing(document as unknown as Record<string, unknown>),
    );
  }

  async resolvePricing(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId: string,
    branchId: string,
    effectiveAt: Date,
  ): Promise<ServicePricingRecord | null> {
    const document = await this.pricingModel
      .findOne(
        createActiveTenantFilter(scope.tenantId, {
          serviceId: new Types.ObjectId(serviceId),
          itemCategoryId: new Types.ObjectId(itemCategoryId),
          branchId: { $in: [branchId, null] },
          status: CatalogStatus.ACTIVE,
          effectiveFrom: { $lte: effectiveAt },
          $or: [{ effectiveTo: null }, { effectiveTo: { $gt: effectiveAt } }],
        }),
      )
      .sort({ branchId: -1, effectiveFrom: -1 })
      .lean()
      .exec();
    return document ? this.mapPricing(document) : null;
  }

  async hasAnyTenantWidePricing(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId: string,
  ): Promise<boolean> {
    return (
      (await this.pricingModel
        .countDocuments({
          tenantId: new Types.ObjectId(scope.tenantId),
          serviceId: new Types.ObjectId(serviceId),
          itemCategoryId: new Types.ObjectId(itemCategoryId),
          branchId: null,
        })
        .exec()) > 0
    );
  }

  private createFields(scope: CatalogScope, input: object): object {
    return {
      ...input,
      ...createAuditFields(scope.actorId),
      tenantId: new Types.ObjectId(scope.tenantId),
    };
  }

  private async findOne<T>(
    model: Model<T>,
    scope: CatalogScope,
    id: string,
  ): Promise<Record<string, unknown> | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const document = await model
      .findOne(createActiveTenantFilter(scope.tenantId, { _id: id }))
      .lean()
      .exec();
    return document;
  }

  private async updateOne<T>(
    model: Model<T>,
    scope: CatalogScope,
    id: string,
    input: object,
  ): Promise<Record<string, unknown> | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const document = await model
      .findOneAndUpdate(
        createActiveTenantFilter(scope.tenantId, { _id: id }),
        { $set: { ...input, updatedBy: new Types.ObjectId(scope.actorId) } },
        { new: true, runValidators: true },
      )
      .lean()
      .exec();
    return document;
  }

  private async listModel<T>(
    model: Model<T>,
    scope: CatalogScope,
    query: CatalogListQuery,
    nameField: string,
    extra: Record<string, unknown> = {},
  ): Promise<{ items: Record<string, unknown>[]; total: number; page: number; limit: number }> {
    const filter: Record<string, unknown> = createActiveTenantFilter(scope.tenantId, extra);
    if (query.status) filter.status = query.status;
    if (query.branchId) filter.$and = [{ $or: [{ branchIds: [] }, { branchIds: query.branchId }] }];
    if (query.search) {
      const expression = new RegExp(escapeRegex(query.search), 'i');
      filter.$or = [{ [nameField]: expression }, { code: expression }];
    }
    const sortField = query.sortBy === 'name' ? nameField : query.sortBy;
    const skip = (query.page - 1) * query.limit;
    const [documents, total] = await Promise.all([
      model
        .find(filter)
        .sort({ [sortField]: query.sortDirection, _id: 1 })
        .skip(skip)
        .limit(query.limit)
        .lean()
        .exec(),
      model.countDocuments(filter).exec(),
    ]);
    return {
      items: documents as unknown as Record<string, unknown>[],
      total,
      page: query.page,
      limit: query.limit,
    };
  }

  private base(
    record: Record<string, unknown>,
  ): Omit<
    ServiceRecord,
    | 'categoryId'
    | 'serviceName'
    | 'name'
    | 'code'
    | 'description'
    | 'pricingType'
    | 'estimatedTimeMins'
    | 'branchIds'
    | 'itemCategoryIds'
    | 'currentPricing'
  > {
    return {
      id: String(record._id),
      tenantId: String(record.tenantId),
      status: record.status as CatalogStatus,
      ...(this.identifier(record.createdBy)
        ? { createdBy: this.identifier(record.createdBy) }
        : {}),
      ...(this.identifier(record.updatedBy)
        ? { updatedBy: this.identifier(record.updatedBy) }
        : {}),
      createdAt: record.createdAt as Date,
      updatedAt: record.updatedAt as Date,
      version: Number(record.version ?? 0),
    };
  }

  private mapItem(record: Record<string, unknown>): ItemCategoryRecord {
    return {
      ...this.base(record),
      name: String(record.name),
      code: String(record.code),
      unitType: record.unitType as UnitType,
      branchIds: Array.isArray(record.branchIds) ? record.branchIds.map(String) : [],
      catalogGroupCodes: Array.isArray(record.catalogGroupCodes)
        ? record.catalogGroupCodes.map(String)
        : [],
      ...(this.text(record.description) ? { description: this.text(record.description) } : {}),
      ...(this.text(record.category) ? { category: this.text(record.category) } : {}),
    };
  }

  private mapTemplate(record: Record<string, unknown>): CatalogTemplateRecord {
    const items = (record.items as Record<string, unknown>[] | undefined) ?? [];
    const services = (record.services as Record<string, unknown>[] | undefined) ?? [];
    const mappings = (record.mappings as Record<string, unknown>[] | undefined) ?? [];
    const pricing = (record.pricing as Record<string, unknown>[] | undefined) ?? [];
    return {
      code: String(record.code),
      businessType: record.businessType as CatalogBusinessType,
      name: String(record.name),
      status: record.status as CatalogStatus,
      templateVersion: Number(record.templateVersion),
      items: items.map((item) => ({
        code: String(item.code),
        name: String(item.name),
        unitType: item.unitType as UnitType,
        ...(typeof item.description === 'string' ? { description: item.description } : {}),
      })),
      services: services.map((service) => ({
        code: String(service.code),
        name: String(service.name),
        pricingType: service.pricingType as PricingType,
        ...(typeof service.description === 'string' ? { description: service.description } : {}),
      })),
      mappings: mappings.map((mapping) => ({
        itemCode: String(mapping.itemCode),
        serviceCode: String(mapping.serviceCode),
        requiresPricingConfiguration: Boolean(mapping.requiresPricingConfiguration),
      })),
      pricing: pricing.map((price) => ({
        itemCode: String(price.itemCode),
        serviceCode: String(price.serviceCode),
        basePrice: Number(price.basePrice),
        taxPct: Number(price.taxPct),
        effectiveFrom: price.effectiveFrom as Date,
      })),
    };
  }

  private mapService(record: Record<string, unknown>): ServiceRecord {
    const serviceName = String(record.serviceName);
    return {
      ...this.base(record),
      serviceName,
      name: serviceName,
      code: String(record.code),
      pricingType: record.pricingType as PricingType,
      branchIds: Array.isArray(record.branchIds) ? record.branchIds.map(String) : [],
      ...(this.identifier(record.categoryId)
        ? { categoryId: this.identifier(record.categoryId) }
        : {}),
      ...(this.text(record.description) ? { description: this.text(record.description) } : {}),
      ...(record.estimatedTimeMins !== undefined
        ? { estimatedTimeMins: Number(record.estimatedTimeMins) }
        : {}),
    };
  }

  private mapServiceCategory(record: Record<string, unknown>): ServiceCategoryRecord {
    return {
      ...this.base(record),
      name: String(record.name),
      code: String(record.code),
      branchIds: Array.isArray(record.branchIds) ? record.branchIds.map(String) : [],
      ...(this.text(record.description) ? { description: this.text(record.description) } : {}),
    };
  }

  private mapMapping(record: Record<string, unknown>): ServiceMappingRecord {
    return {
      ...this.base(record),
      itemCategoryId: String(record.itemCategoryId),
      serviceId: String(record.serviceId),
      branchId: this.text(record.branchId) ?? null,
      pricingType: record.pricingType as PricingType,
      requiresPricingConfiguration: Boolean(record.requiresPricingConfiguration),
    };
  }

  private mapPricing(record: Record<string, unknown>): ServicePricingRecord {
    return {
      ...this.base(record),
      itemCategoryId: String(record.itemCategoryId),
      serviceId: String(record.serviceId),
      branchId: this.text(record.branchId) ?? null,
      pricingType: record.pricingType as PricingType,
      basePrice: Number(record.basePrice),
      taxPct: Number(record.taxPct),
      effectiveFrom: record.effectiveFrom as Date,
      ...(record.effectiveTo ? { effectiveTo: record.effectiveTo as Date } : {}),
    };
  }

  private identifier(value: unknown): string | undefined {
    if (typeof value === 'string') return value;
    return value instanceof Types.ObjectId ? value.toHexString() : undefined;
  }

  private text(value: unknown): string | undefined {
    return typeof value === 'string' ? value : undefined;
  }
}
