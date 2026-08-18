import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import type { CreateItemCategoryDto } from './dtos/create-item-category.dto';
import type { CreateServiceDto } from './dtos/create-service.dto';
import type { ItemCategoryQueryDto } from './dtos/item-category-query.dto';
import type { QuoteQueryDto } from './dtos/quote-query.dto';
import type {
  CreateServiceCategoryDto,
  UpdateServiceCategoryDto,
} from './dtos/service-category.dto';
import type {
  CreateServiceMappingDto,
  ServiceMappingQueryDto,
  UpdateServiceMappingDto,
} from './dtos/service-mapping.dto';
import type { CreateServicePricingDto, UpdateServicePricingDto } from './dtos/service-pricing.dto';
import type { ServiceQueryDto } from './dtos/service-query.dto';
import type { UpdateItemCategoryDto } from './dtos/update-item-category.dto';
import type { UpdateServiceDto } from './dtos/update-service.dto';
import { CatalogStatus, PricingType } from './enums';
import {
  CATALOG_DEPENDENCIES,
  CATALOG_REPOSITORY,
  type CatalogDependencies,
  type CatalogPage,
  type CatalogRepository,
  type CatalogScope,
  type ItemCategoryRecord,
  type ServiceCategoryRecord,
  type ServiceMappingRecord,
  type ServicePricingRecord,
  type ServiceRecord,
} from './catalog.types';

const READ_ROLES = new Set(['tenant_owner', 'branch_manager', 'staff', 'cashier']);
const MANAGE_ROLES = new Set(['tenant_owner', 'branch_manager']);

export interface QuoteRecord {
  readonly serviceId: string;
  readonly itemCategoryId: string;
  readonly branchId: string;
  readonly serviceMappingId: string;
  readonly servicePricingId: string;
  readonly version: number;
  readonly pricingType: PricingType;
  readonly basePrice: number;
  readonly unitPrice: number;
  readonly taxPct: number;
  readonly quantity?: number;
  readonly weight?: number;
  readonly subtotal?: number;
  readonly lineAmount?: number;
  readonly effectiveFrom: Date;
  readonly effectiveTo?: Date;
}

@Injectable()
export class CatalogService {
  constructor(
    @Inject(CATALOG_REPOSITORY) private readonly repository: CatalogRepository,
    @Inject(CATALOG_DEPENDENCIES) private readonly dependencies: CatalogDependencies,
  ) {}

  async createItemCategory(
    scope: CatalogScope,
    input: CreateItemCategoryDto,
  ): Promise<ItemCategoryRecord> {
    this.assertManage(scope);
    await this.validateBranches(scope, input.branchIds);
    return this.duplicateSafe(
      () =>
        this.repository.createItemCategory(scope, {
          name: input.name.trim(),
          code: this.code(input.code),
          description: input.description?.trim(),
          category: input.category?.trim(),
          unitType: input.unitType,
          status: input.status ?? CatalogStatus.ACTIVE,
          branchIds: this.branches(input.branchIds),
        }),
      'Item category code already exists in this tenant',
    );
  }

  async listItemCategories(
    scope: CatalogScope,
    query: ItemCategoryQueryDto,
  ): Promise<CatalogPage<ItemCategoryRecord>> {
    this.assertRead(scope);
    this.validateQueryBranch(scope, query.branchId);
    const page = await this.repository.listItemCategories(scope, {
      ...this.listQuery(query),
      branchId: query.branchId ?? scope.branchId,
    });
    const items = await Promise.all(page.items.map((item) => this.withItemServices(scope, item)));
    return { ...page, items };
  }

  async getItemCategory(scope: CatalogScope, id: string): Promise<ItemCategoryRecord> {
    this.assertRead(scope);
    const item = await this.repository.findItemCategory(scope, id);
    if (!item) throw new NotFoundException('Item category not found');
    this.assertAvailable(item.branchIds, scope.branchId, 'Item category');
    return this.withItemServices(scope, item);
  }

  async updateItemCategory(
    scope: CatalogScope,
    id: string,
    input: UpdateItemCategoryDto,
  ): Promise<ItemCategoryRecord> {
    this.assertManage(scope);
    this.assertPatch(input);
    await this.validateBranches(scope, input.branchIds);
    await this.getItemCategory(scope, id);
    const result = await this.duplicateSafe(
      () =>
        this.repository.updateItemCategory(scope, id, {
          ...(input.name !== undefined ? { name: input.name.trim() } : {}),
          ...(input.code !== undefined ? { code: this.code(input.code) } : {}),
          ...(input.description !== undefined ? { description: input.description.trim() } : {}),
          ...(input.category !== undefined ? { category: input.category.trim() } : {}),
          ...(input.unitType !== undefined ? { unitType: input.unitType } : {}),
          ...(input.status !== undefined ? { status: input.status } : {}),
          ...(input.branchIds !== undefined ? { branchIds: this.branches(input.branchIds) } : {}),
        }),
      'Item category code already exists in this tenant',
    );
    if (!result) throw new NotFoundException('Item category not found');
    return this.withItemServices(scope, result);
  }

  async deactivateItemCategory(scope: CatalogScope, id: string): Promise<ItemCategoryRecord> {
    this.assertManage(scope);
    await this.getItemCategory(scope, id);
    const mappings = await this.repository.listMappings(scope, {
      itemCategoryId: id,
      branchId: scope.branchId,
      status: CatalogStatus.ACTIVE,
    });
    if (mappings.length > 0)
      throw new ConflictException(
        'Deactivate active service mappings before deactivating this item category',
      );
    const result = await this.repository.updateItemCategory(scope, id, {
      status: CatalogStatus.INACTIVE,
    });
    if (!result) throw new NotFoundException('Item category not found');
    return result;
  }

  async createService(scope: CatalogScope, input: CreateServiceDto): Promise<ServiceRecord> {
    this.assertManage(scope);
    await this.validateBranches(scope, input.branchIds);
    if (input.categoryId) await this.requireServiceCategory(scope, input.categoryId, true);
    return this.duplicateSafe(
      () =>
        this.repository.createService(scope, {
          ...(input.categoryId ? { categoryId: input.categoryId } : {}),
          serviceName: input.name.trim(),
          code: this.code(input.code),
          description: input.description?.trim(),
          pricingType: input.pricingType,
          estimatedTimeMins: input.estimatedTimeMins,
          status: input.status ?? CatalogStatus.ACTIVE,
          branchIds: this.branches(input.branchIds),
        }),
      'Service code already exists in this tenant',
    );
  }

  async listServices(
    scope: CatalogScope,
    query: ServiceQueryDto,
  ): Promise<CatalogPage<ServiceRecord>> {
    this.assertRead(scope);
    this.validateQueryBranch(scope, query.branchId);
    const page = await this.repository.listServices(scope, {
      ...this.listQuery(query),
      branchId: query.branchId ?? scope.branchId,
      ...(query.categoryId ? { categoryId: query.categoryId } : {}),
    });
    const items = await Promise.all(
      page.items.map((service) => this.withServiceItems(scope, service)),
    );
    return { ...page, items };
  }

  async getService(scope: CatalogScope, id: string): Promise<ServiceRecord> {
    this.assertRead(scope);
    const service = await this.repository.findService(scope, id);
    if (!service) throw new NotFoundException('Service not found');
    this.assertAvailable(service.branchIds, scope.branchId, 'Service');
    return this.withServiceItems(scope, service);
  }

  async updateService(
    scope: CatalogScope,
    id: string,
    input: UpdateServiceDto,
  ): Promise<ServiceRecord> {
    this.assertManage(scope);
    this.assertPatch(input);
    await this.validateBranches(scope, input.branchIds);
    if (input.categoryId) await this.requireServiceCategory(scope, input.categoryId, true);
    const existing = await this.getService(scope, id);
    if (input.pricingType && input.pricingType !== existing.pricingType) {
      const mappings = await this.repository.listMappings(scope, {
        serviceId: id,
        branchId: scope.branchId,
        status: CatalogStatus.ACTIVE,
      });
      if (mappings.length > 0)
        throw new ConflictException('Pricing type cannot change while active mappings exist');
    }
    const result = await this.duplicateSafe(
      () =>
        this.repository.updateService(scope, id, {
          ...(input.categoryId !== undefined ? { categoryId: input.categoryId } : {}),
          ...(input.name !== undefined ? { serviceName: input.name.trim() } : {}),
          ...(input.code !== undefined ? { code: this.code(input.code) } : {}),
          ...(input.description !== undefined ? { description: input.description.trim() } : {}),
          ...(input.pricingType !== undefined ? { pricingType: input.pricingType } : {}),
          ...(input.estimatedTimeMins !== undefined
            ? { estimatedTimeMins: input.estimatedTimeMins }
            : {}),
          ...(input.status !== undefined ? { status: input.status } : {}),
          ...(input.branchIds !== undefined ? { branchIds: this.branches(input.branchIds) } : {}),
        }),
      'Service code already exists in this tenant',
    );
    if (!result) throw new NotFoundException('Service not found');
    return this.withServiceItems(scope, result);
  }

  async deactivateService(scope: CatalogScope, id: string): Promise<ServiceRecord> {
    this.assertManage(scope);
    await this.getService(scope, id);
    const mappings = await this.repository.listMappings(scope, {
      serviceId: id,
      branchId: scope.branchId,
      status: CatalogStatus.ACTIVE,
    });
    if (mappings.length > 0)
      throw new ConflictException(
        'Deactivate active service mappings before deactivating this service',
      );
    const result = await this.repository.updateService(scope, id, {
      status: CatalogStatus.INACTIVE,
    });
    if (!result) throw new NotFoundException('Service not found');
    return result;
  }

  async createServiceCategory(
    scope: CatalogScope,
    input: CreateServiceCategoryDto,
  ): Promise<ServiceCategoryRecord> {
    this.assertManage(scope);
    await this.validateBranches(scope, input.branchIds);
    return this.duplicateSafe(
      () =>
        this.repository.createServiceCategory(scope, {
          name: input.name.trim(),
          code: this.code(input.code),
          description: input.description?.trim(),
          branchIds: this.branches(input.branchIds),
          status: input.status ?? CatalogStatus.ACTIVE,
        }),
      'Service category code already exists in this tenant',
    );
  }

  async listServiceCategories(
    scope: CatalogScope,
    query: ItemCategoryQueryDto,
  ): Promise<CatalogPage<ServiceCategoryRecord>> {
    this.assertRead(scope);
    this.validateQueryBranch(scope, query.branchId);
    return this.repository.listServiceCategories(scope, {
      ...this.listQuery(query),
      branchId: query.branchId ?? scope.branchId,
    });
  }

  async updateServiceCategory(
    scope: CatalogScope,
    id: string,
    input: UpdateServiceCategoryDto,
  ): Promise<ServiceCategoryRecord> {
    this.assertManage(scope);
    this.assertPatch(input);
    await this.validateBranches(scope, input.branchIds);
    await this.requireServiceCategory(scope, id, false);
    const result = await this.duplicateSafe(
      () =>
        this.repository.updateServiceCategory(scope, id, {
          ...(input.name !== undefined ? { name: input.name.trim() } : {}),
          ...(input.code !== undefined ? { code: this.code(input.code) } : {}),
          ...(input.description !== undefined ? { description: input.description.trim() } : {}),
          ...(input.branchIds !== undefined ? { branchIds: this.branches(input.branchIds) } : {}),
          ...(input.status !== undefined ? { status: input.status } : {}),
        }),
      'Service category code already exists in this tenant',
    );
    if (!result) throw new NotFoundException('Service category not found');
    return result;
  }

  async createMapping(
    scope: CatalogScope,
    input: CreateServiceMappingDto,
  ): Promise<ServiceMappingRecord> {
    this.assertManage(scope);
    if (input.branchId) await this.dependencies.assertBranches(scope, [input.branchId]);
    const [service, item] = await Promise.all([
      this.requireService(scope, input.serviceId, true),
      this.requireItem(scope, input.itemCategoryId, true),
    ]);
    this.assertAvailable(service.branchIds, input.branchId ?? scope.branchId, 'Service');
    this.assertAvailable(item.branchIds, input.branchId ?? scope.branchId, 'Item category');
    return this.duplicateSafe(
      () =>
        this.repository.createMapping(scope, {
          serviceId: input.serviceId,
          itemCategoryId: input.itemCategoryId,
          branchId: input.branchId ?? null,
          pricingType: service.pricingType,
          status: CatalogStatus.ACTIVE,
          requiresPricingConfiguration: input.requiresPricingConfiguration ?? false,
        }),
      'This item category and service mapping already exists for the selected scope',
    );
  }

  listMappings(
    scope: CatalogScope,
    query: ServiceMappingQueryDto,
  ): Promise<readonly ServiceMappingRecord[]> {
    this.assertRead(scope);
    if (query.branchId && query.branchId !== scope.branchId)
      throw new ForbiddenException('Requested branch is outside the authenticated context');
    return this.repository.listMappings(scope, {
      ...query,
      branchId: query.branchId ?? scope.branchId,
    });
  }

  async updateMapping(
    scope: CatalogScope,
    id: string,
    input: UpdateServiceMappingDto,
  ): Promise<ServiceMappingRecord> {
    this.assertManage(scope);
    this.assertPatch(input);
    const existing = await this.repository.findMapping(scope, id);
    if (!existing) throw new NotFoundException('Service mapping not found');
    if (existing.branchId && existing.branchId !== scope.branchId)
      throw new ForbiddenException('Service mapping is outside the authenticated branch');
    const result = await this.repository.updateMapping(scope, id, input);
    if (!result) throw new NotFoundException('Service mapping not found');
    return result;
  }

  async deactivateMapping(scope: CatalogScope, id: string): Promise<ServiceMappingRecord> {
    this.assertManage(scope);
    const existing = await this.repository.findMapping(scope, id);
    if (!existing) throw new NotFoundException('Service mapping not found');
    if (existing.branchId && existing.branchId !== scope.branchId)
      throw new ForbiddenException('Service mapping is outside the authenticated branch');
    const result = await this.repository.updateMapping(scope, id, {
      status: CatalogStatus.INACTIVE,
    });
    if (!result) throw new NotFoundException('Service mapping not found');
    return result;
  }

  async createPricing(
    scope: CatalogScope,
    serviceId: string,
    input: CreateServicePricingDto,
  ): Promise<ServicePricingRecord> {
    this.assertManage(scope);
    if (input.branchId) await this.dependencies.assertBranches(scope, [input.branchId]);
    const service = await this.requireService(scope, serviceId, true);
    await this.requireItem(scope, input.itemCategoryId, true);
    const mapping = await this.repository.findEffectiveMapping(
      scope,
      serviceId,
      input.itemCategoryId,
      input.branchId ?? scope.branchId,
    );
    if (!mapping || (input.branchId === undefined && mapping.branchId !== null))
      throw new BadRequestException('An active mapping is required for this pricing scope');
    const from = new Date(input.effectiveFrom);
    const to = input.effectiveTo ? new Date(input.effectiveTo) : undefined;
    if (to && to <= from)
      throw new BadRequestException('effectiveTo must be later than effectiveFrom');
    const result = await this.repository.createPricingIfNoOverlap(scope, {
      serviceId,
      itemCategoryId: input.itemCategoryId,
      branchId: input.branchId ?? null,
      pricingType: service.pricingType,
      effectiveFrom: from,
      ...(to ? { effectiveTo: to } : {}),
      basePrice: input.basePrice,
      taxPct: input.taxPct ?? 0,
      status: input.status ?? CatalogStatus.ACTIVE,
    });
    if (!result)
      throw new ConflictException(
        'Active pricing windows cannot overlap for the same catalog scope',
      );
    if (mapping.requiresPricingConfiguration) {
      await this.repository.updateMapping(scope, mapping.id, {
        requiresPricingConfiguration: false,
      });
    }
    return result;
  }

  async updatePricing(
    scope: CatalogScope,
    serviceId: string,
    pricingId: string,
    input: UpdateServicePricingDto,
  ): Promise<ServicePricingRecord> {
    this.assertManage(scope);
    this.assertPatch(input);
    await this.requireService(scope, serviceId, false);
    const existing = await this.repository.findPricing(scope, serviceId, pricingId);
    if (!existing) throw new NotFoundException('Service pricing version not found');

    const effectiveTo = input.effectiveTo ? new Date(input.effectiveTo) : undefined;
    if (effectiveTo && effectiveTo <= existing.effectiveFrom) {
      throw new BadRequestException('effectiveTo must be later than effectiveFrom');
    }
    if (
      effectiveTo &&
      existing.effectiveTo &&
      effectiveTo.getTime() !== existing.effectiveTo.getTime()
    ) {
      throw new ConflictException('A closed pricing window cannot be changed');
    }

    const result = await this.repository.updatePricingLifecycle(scope, serviceId, pricingId, {
      ...(effectiveTo ? { effectiveTo } : {}),
      ...(input.status ? { status: input.status } : {}),
    });
    if (!result) throw new NotFoundException('Service pricing version not found');
    return result;
  }

  async listPricing(
    scope: CatalogScope,
    serviceId: string,
    itemCategoryId?: string,
  ): Promise<readonly ServicePricingRecord[]> {
    this.assertRead(scope);
    await this.requireService(scope, serviceId, false);
    return this.repository.listPricing(scope, serviceId, itemCategoryId);
  }

  async quote(scope: CatalogScope, serviceId: string, query: QuoteQueryDto): Promise<QuoteRecord> {
    this.assertRead(scope);
    const branchId = query.branchId ?? scope.branchId;
    if (branchId !== scope.branchId)
      throw new ForbiddenException('Quote branch must match the authenticated branch');
    const [service, item] = await Promise.all([
      this.requireService(scope, serviceId, true),
      this.requireItem(scope, query.itemCategoryId, true),
    ]);
    this.assertAvailable(service.branchIds, branchId, 'Service');
    this.assertAvailable(item.branchIds, branchId, 'Item category');
    const mapping = await this.repository.findEffectiveMapping(
      scope,
      serviceId,
      query.itemCategoryId,
      branchId,
    );
    if (!mapping)
      throw new BadRequestException(
        'Service is not available for the selected item category and branch',
      );
    const effectiveAt = query.effectiveAt ? new Date(query.effectiveAt) : new Date();
    const pricing = await this.repository.resolvePricing(
      scope,
      serviceId,
      query.itemCategoryId,
      branchId,
      effectiveAt,
    );
    if (!pricing)
      throw new NotFoundException(
        'No active pricing is effective for this service, item category, and branch',
      );
    const units = this.quoteUnits(pricing.pricingType, query.quantity, query.weight);
    const subtotal = units === undefined ? undefined : this.money(units * pricing.basePrice);
    return {
      serviceId,
      itemCategoryId: query.itemCategoryId,
      branchId,
      serviceMappingId: mapping.id,
      servicePricingId: pricing.id,
      version: pricing.version,
      pricingType: pricing.pricingType,
      basePrice: pricing.basePrice,
      unitPrice: pricing.basePrice,
      taxPct: pricing.taxPct,
      ...(query.quantity !== undefined ? { quantity: query.quantity } : {}),
      ...(query.weight !== undefined ? { weight: query.weight } : {}),
      ...(subtotal !== undefined ? { subtotal, lineAmount: subtotal } : {}),
      effectiveFrom: pricing.effectiveFrom,
      ...(pricing.effectiveTo ? { effectiveTo: pricing.effectiveTo } : {}),
    };
  }

  private async requireService(
    scope: CatalogScope,
    id: string,
    active: boolean,
  ): Promise<ServiceRecord> {
    const service = await this.repository.findService(scope, id);
    if (!service) throw new NotFoundException('Service not found');
    this.assertAvailable(service.branchIds, scope.branchId, 'Service');
    if (active && service.status !== CatalogStatus.ACTIVE)
      throw new BadRequestException('Service is inactive');
    return service;
  }
  private async requireItem(
    scope: CatalogScope,
    id: string,
    active: boolean,
  ): Promise<ItemCategoryRecord> {
    const item = await this.repository.findItemCategory(scope, id);
    if (!item) throw new NotFoundException('Item category not found');
    this.assertAvailable(item.branchIds, scope.branchId, 'Item category');
    if (active && item.status !== CatalogStatus.ACTIVE)
      throw new BadRequestException('Item category is inactive');
    return item;
  }
  private async requireServiceCategory(
    scope: CatalogScope,
    id: string,
    active: boolean,
  ): Promise<ServiceCategoryRecord> {
    const category = await this.repository.findServiceCategory(scope, id);
    if (!category) throw new NotFoundException('Service category not found');
    this.assertAvailable(category.branchIds, scope.branchId, 'Service category');
    if (active && category.status !== CatalogStatus.ACTIVE)
      throw new BadRequestException('Service category is inactive');
    return category;
  }
  private async withServiceItems(
    scope: CatalogScope,
    service: ServiceRecord,
  ): Promise<ServiceRecord> {
    const mappings = await this.repository.listMappings(scope, {
      serviceId: service.id,
      branchId: scope.branchId,
      status: CatalogStatus.ACTIVE,
    });
    const currentPricing = (
      await Promise.all(
        mappings.map((mapping) =>
          this.repository.resolvePricing(
            scope,
            service.id,
            mapping.itemCategoryId,
            scope.branchId,
            new Date(),
          ),
        ),
      )
    ).filter((pricing): pricing is ServicePricingRecord => pricing !== null);
    return {
      ...service,
      itemCategoryIds: [...new Set(mappings.map((mapping) => mapping.itemCategoryId))],
      currentPricing,
    };
  }
  private async withItemServices(
    scope: CatalogScope,
    item: ItemCategoryRecord,
  ): Promise<ItemCategoryRecord> {
    const mappings = await this.repository.listMappings(scope, {
      itemCategoryId: item.id,
      branchId: scope.branchId,
      status: CatalogStatus.ACTIVE,
    });
    return { ...item, serviceIds: [...new Set(mappings.map((mapping) => mapping.serviceId))] };
  }
  private quoteUnits(type: PricingType, quantity?: number, weight?: number): number | undefined {
    if (quantity === undefined && weight === undefined)
      return type === PricingType.FIXED ? 1 : undefined;
    if (type === PricingType.PER_KG) {
      if (weight === undefined || quantity !== undefined)
        throw new BadRequestException('PerKg pricing requires weight and does not accept quantity');
      return weight;
    }
    if (type === PricingType.CUSTOM) {
      if ((quantity === undefined) === (weight === undefined))
        throw new BadRequestException('Custom pricing requires exactly one of quantity or weight');
      return quantity ?? weight;
    }
    if (weight !== undefined)
      throw new BadRequestException(`${type} pricing does not accept weight`);
    if (type === PricingType.FIXED) {
      if (quantity !== undefined && quantity !== 1)
        throw new BadRequestException('Fixed pricing accepts only quantity 1');
      return 1;
    }
    if (quantity === undefined) throw new BadRequestException(`${type} pricing requires quantity`);
    return quantity;
  }
  private assertAvailable(branchIds: readonly string[], branchId: string, label: string): void {
    if (branchIds.length > 0 && !branchIds.includes(branchId))
      throw new ForbiddenException(`${label} is unavailable in the authenticated branch`);
  }
  private assertRead(scope: CatalogScope): void {
    if (!READ_ROLES.has(scope.roleCode))
      throw new ForbiddenException('Catalog access is forbidden for this role');
  }
  private assertManage(scope: CatalogScope): void {
    if (!MANAGE_ROLES.has(scope.roleCode))
      throw new ForbiddenException('Catalog modification is forbidden for this role');
  }
  private assertPatch(input: object): void {
    if (Object.keys(input).length === 0)
      throw new BadRequestException('At least one mutable field is required');
  }
  private async validateBranches(
    scope: CatalogScope,
    branchIds?: readonly string[],
  ): Promise<void> {
    if (branchIds) await this.dependencies.assertBranches(scope, this.branches(branchIds));
  }
  private validateQueryBranch(scope: CatalogScope, branchId?: string): void {
    if (branchId && branchId !== scope.branchId)
      throw new ForbiddenException('Requested branch is outside the authenticated context');
  }
  private branches(branchIds?: readonly string[]): string[] {
    return [...new Set((branchIds ?? []).map((id) => id.trim()).filter(Boolean))];
  }
  private code(value: string): string {
    return value.trim().toUpperCase();
  }
  private listQuery(query: ItemCategoryQueryDto): {
    page: number;
    limit: number;
    search?: string;
    status?: CatalogStatus;
    branchId?: string;
    sortBy: 'name' | 'code' | 'createdAt' | 'updatedAt';
    sortDirection: 1 | -1;
  } {
    return {
      page: query.page,
      limit: query.limit,
      ...(query.search?.trim() ? { search: query.search.trim() } : {}),
      ...(query.status ? { status: query.status } : {}),
      ...(query.branchId ? { branchId: query.branchId } : {}),
      sortBy: query.sortBy,
      sortDirection: query.sortDirection === 'asc' ? 1 : -1,
    };
  }
  private async duplicateSafe<T>(operation: () => Promise<T>, message: string): Promise<T> {
    try {
      return await operation();
    } catch (error) {
      if (typeof error === 'object' && error !== null && 'code' in error && error.code === 11000)
        throw new ConflictException(message);
      throw error;
    }
  }
  private money(value: number): number {
    return Math.round((value + Number.EPSILON) * 100) / 100;
  }
}
