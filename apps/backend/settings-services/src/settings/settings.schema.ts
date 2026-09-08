import { Prop } from '@nestjs/mongoose';
import { BaseSchema, createBaseSchema, DatabaseSchema } from '@nexoraa/database';
import { Schema as MongooseSchema, Types } from 'mongoose';

import { CatalogStatus, PricingType, UnitType } from './enums';

@DatabaseSchema({ collection: 'serviceCategories' })
export class SettingsServiceCategoryMongoose extends BaseSchema {
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

export const SettingsServiceCategoryMongooseSchema = createBaseSchema(
  SettingsServiceCategoryMongoose,
);
SettingsServiceCategoryMongooseSchema.index(
  { tenantId: 1, code: 1 },
  { name: 'settings_service_categories_tenant_code_unique', unique: true },
);
SettingsServiceCategoryMongooseSchema.index({ tenantId: 1, status: 1, name: 1 });

@DatabaseSchema({ collection: 'itemCategories' })
export class SettingsItemCategoryMongoose extends BaseSchema {
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

export const SettingsItemCategoryMongooseSchema = createBaseSchema(SettingsItemCategoryMongoose);
SettingsItemCategoryMongooseSchema.index(
  { tenantId: 1, code: 1 },
  { name: 'settings_item_categories_tenant_code_unique', unique: true },
);
SettingsItemCategoryMongooseSchema.index({ tenantId: 1, status: 1, name: 1 });
SettingsItemCategoryMongooseSchema.index({ tenantId: 1, branchIds: 1, status: 1 });

@DatabaseSchema({ collection: 'services' })
export class SettingsServiceMongoose extends BaseSchema {
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

export const SettingsServiceMongooseSchema = createBaseSchema(SettingsServiceMongoose);
SettingsServiceMongooseSchema.index(
  { tenantId: 1, code: 1 },
  { name: 'settings_services_tenant_code_unique', unique: true },
);
SettingsServiceMongooseSchema.index({ tenantId: 1, status: 1, serviceName: 1 });
SettingsServiceMongooseSchema.index({ tenantId: 1, branchIds: 1, status: 1 });

@DatabaseSchema({ collection: 'serviceMappings' })
export class SettingsServiceMappingMongoose extends BaseSchema {
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

export const SettingsServiceMappingMongooseSchema = createBaseSchema(
  SettingsServiceMappingMongoose,
);
SettingsServiceMappingMongooseSchema.index(
  { tenantId: 1, itemCategoryId: 1, serviceId: 1, branchId: 1 },
  { name: 'settings_service_mappings_scope_unique', unique: true },
);
SettingsServiceMappingMongooseSchema.index({ tenantId: 1, serviceId: 1, status: 1 });
SettingsServiceMappingMongooseSchema.index({ tenantId: 1, itemCategoryId: 1, status: 1 });

@DatabaseSchema({ collection: 'servicePricing' })
export class SettingsServicePricingMongoose extends BaseSchema {
  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  serviceId!: Types.ObjectId;

  @Prop({ immutable: true, required: true, type: MongooseSchema.Types.ObjectId })
  itemCategoryId!: Types.ObjectId;

  @Prop({ default: null, immutable: true, type: String })
  branchId!: string | null;

  @Prop({ enum: PricingType, required: true, type: String })
  pricingType!: PricingType;

  @Prop({ min: 0, required: true, type: Number })
  basePrice!: number;

  @Prop({ default: 0, max: 100, min: 0, required: true, type: Number })
  taxPct!: number;

  @Prop({ required: true, type: Date })
  effectiveFrom!: Date;

  @Prop({ type: Date })
  effectiveTo?: Date;

  @Prop({ default: CatalogStatus.ACTIVE, enum: CatalogStatus, required: true, type: String })
  status!: CatalogStatus;
}

export const SettingsServicePricingMongooseSchema = createBaseSchema(
  SettingsServicePricingMongoose,
);
SettingsServicePricingMongooseSchema.index(
  { tenantId: 1, serviceId: 1, itemCategoryId: 1, branchId: 1, effectiveFrom: -1 },
  { name: 'settings_service_pricing_effective_lookup' },
);
SettingsServicePricingMongooseSchema.index(
  { tenantId: 1, serviceId: 1, itemCategoryId: 1, branchId: 1, pricingType: 1, effectiveFrom: 1 },
  { name: 'settings_service_pricing_version_unique', unique: true },
);
SettingsServicePricingMongooseSchema.index({ tenantId: 1, status: 1, effectiveTo: 1 });
