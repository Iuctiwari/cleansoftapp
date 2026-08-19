import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { BaseSchema, createBaseSchema, DatabaseSchema } from '@nexoraa/database';
import { Schema as MongooseSchema, Types } from 'mongoose';

import { CatalogStatus, PricingType, UnitType } from './enums';

@Schema({ _id: false })
export class CatalogTemplateItemMongoose {
  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  code!: string;

  @Prop({ maxlength: 120, required: true, trim: true, type: String })
  name!: string;

  @Prop({ enum: UnitType, required: true, type: String })
  unitType!: UnitType;

  @Prop({ maxlength: 500, trim: true, type: String })
  description?: string;
}

const CatalogTemplateItemSchema = SchemaFactory.createForClass(CatalogTemplateItemMongoose);

@Schema({ _id: false })
export class CatalogTemplateServiceMongoose {
  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  code!: string;

  @Prop({ maxlength: 120, required: true, trim: true, type: String })
  name!: string;

  @Prop({ enum: PricingType, required: true, type: String })
  pricingType!: PricingType;

  @Prop({ maxlength: 500, trim: true, type: String })
  description?: string;
}

const CatalogTemplateServiceSchema = SchemaFactory.createForClass(CatalogTemplateServiceMongoose);

@Schema({ _id: false })
export class CatalogTemplateMappingMongoose {
  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  itemCode!: string;

  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  serviceCode!: string;

  @Prop({ default: true, required: true, type: Boolean })
  requiresPricingConfiguration!: boolean;
}

const CatalogTemplateMappingSchema = SchemaFactory.createForClass(CatalogTemplateMappingMongoose);

@Schema({ _id: false })
export class CatalogTemplatePricingMongoose {
  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  itemCode!: string;

  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  serviceCode!: string;

  @Prop({ min: 0, required: true, type: Number })
  basePrice!: number;

  @Prop({ default: 0, max: 100, min: 0, required: true, type: Number })
  taxPct!: number;

  @Prop({ required: true, type: Date })
  effectiveFrom!: Date;
}

const CatalogTemplatePricingSchema = SchemaFactory.createForClass(CatalogTemplatePricingMongoose);

@Schema({ collection: 'catalogTemplates', timestamps: true, versionKey: false })
export class CatalogTemplateMongoose {
  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  code!: string;

  @Prop({ maxlength: 40, required: true, trim: true, type: String })
  businessType!: string;

  @Prop({ maxlength: 120, required: true, trim: true, type: String })
  name!: string;

  @Prop({ default: CatalogStatus.ACTIVE, enum: CatalogStatus, required: true, type: String })
  status!: CatalogStatus;

  @Prop({ min: 1, required: true, type: Number })
  templateVersion!: number;

  @Prop({ required: true, type: [CatalogTemplateItemSchema] })
  items!: CatalogTemplateItemMongoose[];

  @Prop({ required: true, type: [CatalogTemplateServiceSchema] })
  services!: CatalogTemplateServiceMongoose[];

  @Prop({ required: true, type: [CatalogTemplateMappingSchema] })
  mappings!: CatalogTemplateMappingMongoose[];

  @Prop({ default: [], required: true, type: [CatalogTemplatePricingSchema] })
  pricing!: CatalogTemplatePricingMongoose[];
}

export const CatalogTemplateMongooseSchema = SchemaFactory.createForClass(CatalogTemplateMongoose);
CatalogTemplateMongooseSchema.index(
  { code: 1 },
  { name: 'catalog_templates_code_unique', unique: true },
);
CatalogTemplateMongooseSchema.index(
  { businessType: 1 },
  { name: 'catalog_templates_business_type_unique', unique: true },
);

@DatabaseSchema({ collection: 'serviceCategories' })
export class ServiceCategoryMongoose extends BaseSchema {
  @Prop({ maxlength: 120, required: true, trim: true, type: String })
  name!: string;

  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  code!: string;

  @Prop({ maxlength: 500, trim: true, type: String })
  description?: string;

  @Prop({ default: CatalogStatus.ACTIVE, enum: CatalogStatus, required: true, type: String })
  status!: CatalogStatus;

  @Prop({ default: [], type: [String] })
  branchIds!: string[];
}

export const ServiceCategoryMongooseSchema = createBaseSchema(ServiceCategoryMongoose);
ServiceCategoryMongooseSchema.index(
  { tenantId: 1, code: 1 },
  { name: 'service_categories_tenant_code_unique', unique: true },
);
ServiceCategoryMongooseSchema.index({ tenantId: 1, status: 1, name: 1 });

@DatabaseSchema({ collection: 'itemCategories' })
export class ItemCategoryMongoose extends BaseSchema {
  @Prop({ maxlength: 120, required: true, trim: true, type: String })
  name!: string;

  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  code!: string;

  @Prop({ maxlength: 500, trim: true, type: String })
  description?: string;

  @Prop({ maxlength: 120, trim: true, type: String })
  category?: string;

  @Prop({ default: [], type: [String] })
  catalogGroupCodes!: string[];

  @Prop({ enum: UnitType, required: true, type: String })
  unitType!: UnitType;

  @Prop({ default: CatalogStatus.ACTIVE, enum: CatalogStatus, required: true, type: String })
  status!: CatalogStatus;

  @Prop({ default: [], type: [String] })
  branchIds!: string[];
}

export const ItemCategoryMongooseSchema = createBaseSchema(ItemCategoryMongoose);
ItemCategoryMongooseSchema.index(
  { tenantId: 1, code: 1 },
  { name: 'item_categories_tenant_code_unique', unique: true },
);
ItemCategoryMongooseSchema.index({ tenantId: 1, status: 1, name: 1 });
ItemCategoryMongooseSchema.index({ tenantId: 1, branchIds: 1, status: 1 });

@DatabaseSchema({ collection: 'services' })
export class ServiceMongoose extends BaseSchema {
  @Prop({ type: MongooseSchema.Types.ObjectId })
  categoryId?: Types.ObjectId;

  @Prop({ maxlength: 120, required: true, trim: true, type: String })
  serviceName!: string;

  @Prop({ maxlength: 40, required: true, trim: true, type: String, uppercase: true })
  code!: string;

  @Prop({ maxlength: 500, trim: true, type: String })
  description?: string;

  @Prop({ enum: PricingType, required: true, type: String })
  pricingType!: PricingType;

  @Prop({ min: 0, type: Number })
  estimatedTimeMins?: number;

  @Prop({ default: [], type: [String] })
  branchIds!: string[];

  @Prop({ default: CatalogStatus.ACTIVE, enum: CatalogStatus, required: true, type: String })
  status!: CatalogStatus;
}

export const ServiceMongooseSchema = createBaseSchema(ServiceMongoose);
ServiceMongooseSchema.index(
  { tenantId: 1, code: 1 },
  { name: 'services_tenant_code_unique', unique: true },
);
ServiceMongooseSchema.index({ tenantId: 1, status: 1, serviceName: 1 });
ServiceMongooseSchema.index({ tenantId: 1, branchIds: 1, status: 1 });

@DatabaseSchema({ collection: 'serviceMappings' })
export class ServiceMappingMongoose extends BaseSchema {
  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  itemCategoryId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  serviceId!: Types.ObjectId;

  @Prop({ default: null, type: String })
  branchId!: string | null;

  @Prop({ enum: PricingType, required: true, type: String })
  pricingType!: PricingType;

  @Prop({ default: CatalogStatus.ACTIVE, enum: CatalogStatus, required: true, type: String })
  status!: CatalogStatus;

  @Prop({ default: false, required: true, type: Boolean })
  requiresPricingConfiguration!: boolean;
}

export const ServiceMappingMongooseSchema = createBaseSchema(ServiceMappingMongoose);
ServiceMappingMongooseSchema.index(
  { tenantId: 1, itemCategoryId: 1, serviceId: 1, branchId: 1 },
  { name: 'service_mappings_scope_unique', unique: true },
);
ServiceMappingMongooseSchema.index({ tenantId: 1, serviceId: 1, status: 1 });
ServiceMappingMongooseSchema.index({ tenantId: 1, itemCategoryId: 1, status: 1 });

@DatabaseSchema({ collection: 'servicePricing' })
export class ServicePricingMongoose extends BaseSchema {
  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  serviceId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  itemCategoryId!: Types.ObjectId;

  @Prop({ default: null, immutable: true, type: String })
  branchId!: string | null;

  @Prop({ enum: PricingType, immutable: true, required: true, type: String })
  pricingType!: PricingType;

  @Prop({ immutable: true, min: 0, required: true, type: Number })
  basePrice!: number;

  @Prop({ default: 0, immutable: true, max: 100, min: 0, required: true, type: Number })
  taxPct!: number;

  @Prop({ immutable: true, required: true, type: Date })
  effectiveFrom!: Date;

  @Prop({ type: Date })
  effectiveTo?: Date;

  @Prop({ default: CatalogStatus.ACTIVE, enum: CatalogStatus, required: true, type: String })
  status!: CatalogStatus;
}

export const ServicePricingMongooseSchema = createBaseSchema(ServicePricingMongoose);
ServicePricingMongooseSchema.index(
  { tenantId: 1, serviceId: 1, itemCategoryId: 1, branchId: 1, effectiveFrom: -1 },
  { name: 'service_pricing_effective_lookup' },
);
ServicePricingMongooseSchema.index(
  { tenantId: 1, serviceId: 1, itemCategoryId: 1, branchId: 1, pricingType: 1, effectiveFrom: 1 },
  { name: 'service_pricing_version_unique', unique: true },
);
ServicePricingMongooseSchema.index({ tenantId: 1, status: 1, effectiveTo: 1 });
