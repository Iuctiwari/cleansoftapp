import type { PaginatedResult } from '@nexoraa/types';

import type { CatalogStatus, PricingType, UnitType } from './enums';

export const CATALOG_REPOSITORY = Symbol('CATALOG_REPOSITORY');
export const CATALOG_DEPENDENCIES = Symbol('CATALOG_DEPENDENCIES');

export type CatalogBusinessType =
  | 'laundry'
  | 'dry_cleaning'
  | 'tailoring'
  | 'shoe_cleaning'
  | 'appliance_repair'
  | 'mobile_repair'
  | 'vehicle_wash'
  | 'salon'
  | 'general'
  | 'custom';

export const CATALOG_BUSINESS_TYPES: readonly CatalogBusinessType[] = Object.freeze([
  'laundry',
  'dry_cleaning',
  'tailoring',
  'shoe_cleaning',
  'appliance_repair',
  'mobile_repair',
  'vehicle_wash',
  'salon',
  'general',
  'custom',
]);

export interface CatalogTemplateRecord {
  readonly code: string;
  readonly businessType: CatalogBusinessType;
  readonly name: string;
  readonly status: CatalogStatus;
  readonly templateVersion: number;
  readonly items: readonly {
    readonly code: string;
    readonly name: string;
    readonly unitType: UnitType;
    readonly description?: string;
  }[];
  readonly services: readonly {
    readonly code: string;
    readonly name: string;
    readonly pricingType: PricingType;
    readonly description?: string;
  }[];
  readonly mappings: readonly {
    readonly itemCode: string;
    readonly serviceCode: string;
    readonly requiresPricingConfiguration: boolean;
  }[];
  readonly pricing: readonly {
    readonly itemCode: string;
    readonly serviceCode: string;
    readonly basePrice: number;
    readonly taxPct: number;
    readonly effectiveFrom: Date;
  }[];
}

export interface CatalogScope {
  readonly actorId: string;
  readonly authorization: string;
  readonly branchId: string;
  readonly permissions: readonly string[];
  readonly roleCode: string;
  readonly tenantId: string;
}

export interface CatalogEntityRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly status: CatalogStatus;
  readonly createdBy?: string;
  readonly updatedBy?: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
  readonly version: number;
}

export interface ItemCategoryRecord extends CatalogEntityRecord {
  readonly name: string;
  readonly code: string;
  readonly description?: string;
  readonly category?: string;
  readonly catalogGroupCodes: readonly string[];
  readonly unitType: UnitType;
  readonly branchIds: readonly string[];
  readonly serviceIds?: readonly string[];
}

export interface ServiceRecord extends CatalogEntityRecord {
  readonly categoryId?: string;
  readonly serviceName: string;
  readonly name: string;
  readonly code: string;
  readonly description?: string;
  readonly pricingType: PricingType;
  readonly estimatedTimeMins?: number;
  readonly branchIds: readonly string[];
  readonly itemCategoryIds?: readonly string[];
  readonly currentPricing?: readonly ServicePricingRecord[];
}

export interface ServiceCategoryRecord extends CatalogEntityRecord {
  readonly name: string;
  readonly code: string;
  readonly description?: string;
  readonly branchIds: readonly string[];
}

export interface ServiceMappingRecord extends CatalogEntityRecord {
  readonly itemCategoryId: string;
  readonly serviceId: string;
  readonly branchId: string | null;
  readonly pricingType: PricingType;
  readonly requiresPricingConfiguration: boolean;
}

export interface ServicePricingRecord extends CatalogEntityRecord {
  readonly serviceId: string;
  readonly itemCategoryId: string;
  readonly branchId: string | null;
  readonly pricingType: PricingType;
  readonly basePrice: number;
  readonly taxPct: number;
  readonly effectiveFrom: Date;
  readonly effectiveTo?: Date;
}

export interface CatalogListQuery {
  readonly page: number;
  readonly limit: number;
  readonly search?: string;
  readonly status?: CatalogStatus;
  readonly branchId?: string;
  readonly sortBy: 'name' | 'code' | 'createdAt' | 'updatedAt';
  readonly sortDirection: 1 | -1;
}

export type CatalogPage<T> = Omit<PaginatedResult<T>, 'totalPages'>;

export interface CatalogRepository {
  listTemplatesByBusinessTypes(
    businessTypes: readonly CatalogBusinessType[],
  ): Promise<readonly CatalogTemplateRecord[]>;
  upsertTemplate(template: CatalogTemplateRecord): Promise<void>;
  createItemCategory(scope: CatalogScope, input: object): Promise<ItemCategoryRecord>;
  findItemCategoryByCode(scope: CatalogScope, code: string): Promise<ItemCategoryRecord | null>;
  findItemCategory(scope: CatalogScope, id: string): Promise<ItemCategoryRecord | null>;
  listItemCategories(
    scope: CatalogScope,
    query: CatalogListQuery,
  ): Promise<CatalogPage<ItemCategoryRecord>>;
  updateItemCategory(
    scope: CatalogScope,
    id: string,
    input: object,
  ): Promise<ItemCategoryRecord | null>;
  createService(scope: CatalogScope, input: object): Promise<ServiceRecord>;
  findServiceByCode(scope: CatalogScope, code: string): Promise<ServiceRecord | null>;
  findService(scope: CatalogScope, id: string): Promise<ServiceRecord | null>;
  listServices(
    scope: CatalogScope,
    query: CatalogListQuery & { categoryId?: string },
  ): Promise<CatalogPage<ServiceRecord>>;
  updateService(scope: CatalogScope, id: string, input: object): Promise<ServiceRecord | null>;
  createServiceCategory(scope: CatalogScope, input: object): Promise<ServiceCategoryRecord>;
  findServiceCategory(scope: CatalogScope, id: string): Promise<ServiceCategoryRecord | null>;
  listServiceCategories(
    scope: CatalogScope,
    query: CatalogListQuery,
  ): Promise<CatalogPage<ServiceCategoryRecord>>;
  updateServiceCategory(
    scope: CatalogScope,
    id: string,
    input: object,
  ): Promise<ServiceCategoryRecord | null>;
  createMapping(scope: CatalogScope, input: object): Promise<ServiceMappingRecord>;
  findTenantWideMapping(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId: string,
  ): Promise<ServiceMappingRecord | null>;
  findMapping(scope: CatalogScope, id: string): Promise<ServiceMappingRecord | null>;
  findEffectiveMapping(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId: string,
    branchId: string,
  ): Promise<ServiceMappingRecord | null>;
  listMappings(
    scope: CatalogScope,
    filters: {
      serviceId?: string;
      itemCategoryId?: string;
      branchId?: string;
      status?: CatalogStatus;
    },
  ): Promise<readonly ServiceMappingRecord[]>;
  updateMapping(
    scope: CatalogScope,
    id: string,
    input: object,
  ): Promise<ServiceMappingRecord | null>;
  createPricingIfNoOverlap(
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
  ): Promise<ServicePricingRecord | null>;
  findPricing(
    scope: CatalogScope,
    serviceId: string,
    pricingId: string,
  ): Promise<ServicePricingRecord | null>;
  updatePricingLifecycle(
    scope: CatalogScope,
    serviceId: string,
    pricingId: string,
    input: { effectiveTo?: Date; status?: CatalogStatus.INACTIVE },
  ): Promise<ServicePricingRecord | null>;
  listPricing(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId?: string,
  ): Promise<readonly ServicePricingRecord[]>;
  resolvePricing(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId: string,
    branchId: string,
    effectiveAt: Date,
  ): Promise<ServicePricingRecord | null>;
  hasAnyTenantWidePricing(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId: string,
  ): Promise<boolean>;
}

export interface CatalogDependencies {
  assertBranches(scope: CatalogScope, branchIds: readonly string[]): Promise<void>;
}
