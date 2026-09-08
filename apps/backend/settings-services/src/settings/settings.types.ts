import type { CatalogStatus, PricingType, UnitType } from './enums';

export const SETTINGS_REPOSITORY = Symbol('SETTINGS_REPOSITORY');

export interface SettingsScope {
  readonly actorId: string;
  readonly authorization: string;
  readonly branchId: string;
  readonly permissions: readonly string[];
  readonly roleCode: string;
  readonly tenantId: string;
}

export interface SettingsEntityRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly status: CatalogStatus;
  readonly createdBy?: string;
  readonly updatedBy?: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
  readonly version: number;
}

export interface SettingsItemRecord extends SettingsEntityRecord {
  readonly name: string;
  readonly code: string;
  readonly description?: string;
  readonly category?: string;
  readonly catalogGroupCodes: readonly string[];
  readonly unitType: UnitType;
  readonly branchIds: readonly string[];
  readonly serviceIds?: readonly string[];
}

export interface SettingsServiceRecord extends SettingsEntityRecord {
  readonly categoryId?: string;
  readonly serviceName: string;
  readonly name: string;
  readonly code: string;
  readonly description?: string;
  readonly pricingType: PricingType;
  readonly estimatedTimeMins?: number;
  readonly branchIds: readonly string[];
  readonly itemCategoryIds?: readonly string[];
  readonly currentPricing?: readonly SettingsPricingRecord[];
}

export interface SettingsCategoryRecord extends SettingsEntityRecord {
  readonly name: string;
  readonly code: string;
  readonly description?: string;
  readonly branchIds: readonly string[];
}

export interface SettingsMappingRecord extends SettingsEntityRecord {
  readonly itemCategoryId: string;
  readonly serviceId: string;
  readonly branchId: string | null;
  readonly pricingType: PricingType;
  readonly requiresPricingConfiguration: boolean;
}

export interface SettingsPricingRecord extends SettingsEntityRecord {
  readonly serviceId: string;
  readonly itemCategoryId: string;
  readonly branchId: string | null;
  readonly pricingType: PricingType;
  readonly basePrice: number;
  readonly taxPct: number;
  readonly effectiveFrom: Date;
  readonly effectiveTo?: Date;
}

export interface BusinessCatalogSettingsSummary {
  readonly tenantId: string;
  readonly totalServices: number;
  readonly totalActiveServices: number;
  readonly totalItems: number;
  readonly totalActiveItems: number;
  readonly totalCategories: number;
  readonly totalActiveCategories: number;
  readonly totalActivePricing: number;
  readonly services: readonly SettingsServiceRecord[];
  readonly items: readonly SettingsItemRecord[];
  readonly categories: readonly SettingsCategoryRecord[];
  readonly pricing: readonly SettingsPricingRecord[];
}

export interface SettingsListQuery {
  readonly search?: string;
  readonly status?: CatalogStatus;
  readonly branchId?: string;
}

export interface SettingsRepository {
  // Service
  listServices(
    scope: SettingsScope,
    query?: SettingsListQuery,
  ): Promise<readonly SettingsServiceRecord[]>;
  findService(scope: SettingsScope, id: string): Promise<SettingsServiceRecord | null>;
  findServiceByCode(scope: SettingsScope, code: string): Promise<SettingsServiceRecord | null>;
  createService(scope: SettingsScope, input: object): Promise<SettingsServiceRecord>;
  updateService(
    scope: SettingsScope,
    id: string,
    input: object,
  ): Promise<SettingsServiceRecord | null>;

  // Item
  listItems(
    scope: SettingsScope,
    query?: SettingsListQuery,
  ): Promise<readonly SettingsItemRecord[]>;
  findItem(scope: SettingsScope, id: string): Promise<SettingsItemRecord | null>;
  findItemByCode(scope: SettingsScope, code: string): Promise<SettingsItemRecord | null>;
  createItem(scope: SettingsScope, input: object): Promise<SettingsItemRecord>;
  updateItem(scope: SettingsScope, id: string, input: object): Promise<SettingsItemRecord | null>;

  // Category
  listCategories(
    scope: SettingsScope,
    query?: SettingsListQuery,
  ): Promise<readonly SettingsCategoryRecord[]>;
  findCategory(scope: SettingsScope, id: string): Promise<SettingsCategoryRecord | null>;
  findCategoryByCode(scope: SettingsScope, code: string): Promise<SettingsCategoryRecord | null>;
  createCategory(scope: SettingsScope, input: object): Promise<SettingsCategoryRecord>;
  updateCategory(
    scope: SettingsScope,
    id: string,
    input: object,
  ): Promise<SettingsCategoryRecord | null>;

  // Pricing & Mappings
  listPricing(
    scope: SettingsScope,
    filters?: {
      serviceId?: string;
      itemCategoryId?: string;
      branchId?: string;
      status?: CatalogStatus;
    },
  ): Promise<readonly SettingsPricingRecord[]>;
  findPricing(scope: SettingsScope, id: string): Promise<SettingsPricingRecord | null>;
  createPricing(scope: SettingsScope, input: object): Promise<SettingsPricingRecord>;
  updatePricing(
    scope: SettingsScope,
    id: string,
    input: object,
  ): Promise<SettingsPricingRecord | null>;
  listMappings(
    scope: SettingsScope,
    filters?: {
      serviceId?: string;
      itemCategoryId?: string;
      branchId?: string;
      status?: CatalogStatus;
    },
  ): Promise<readonly SettingsMappingRecord[]>;
  createMapping(scope: SettingsScope, input: object): Promise<SettingsMappingRecord>;
  updateMapping(
    scope: SettingsScope,
    id: string,
    input: object,
  ): Promise<SettingsMappingRecord | null>;
  findMapping(
    scope: SettingsScope,
    serviceId: string,
    itemCategoryId: string,
    branchId?: string | null,
  ): Promise<SettingsMappingRecord | null>;
}
