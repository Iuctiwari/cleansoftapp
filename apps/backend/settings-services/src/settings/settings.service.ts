import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Permissions, hasPermission, isBranchManagerRole, isOwnerRole } from '@nexoraa/shared';

import type {
  CreateCategorySettingsDto,
  UpdateCategorySettingsDto,
} from './dtos/category-settings.dto';
import type { CreateItemSettingsDto, UpdateItemSettingsDto } from './dtos/item-settings.dto';
import type { UpdatePricingSettingsDto } from './dtos/pricing-settings.dto';
import type { SettingsQueryDto } from './dtos/query-settings.dto';
import type {
  CreateServiceSettingsDto,
  UpdateServiceSettingsDto,
} from './dtos/service-settings.dto';
import { CatalogStatus, PricingType } from './enums';
import {
  type BusinessCatalogSettingsSummary,
  SETTINGS_REPOSITORY,
  type SettingsCategoryRecord,
  type SettingsItemRecord,
  type SettingsPricingRecord,
  type SettingsRepository,
  type SettingsScope,
  type SettingsServiceRecord,
} from './settings.types';

@Injectable()
export class SettingsService {
  constructor(
    @Inject(SETTINGS_REPOSITORY)
    private readonly repository: SettingsRepository,
  ) {}

  // ─────────────────────────────────────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────────────────────────────────────
  async getBusinessCatalogSettings(scope: SettingsScope): Promise<BusinessCatalogSettingsSummary> {
    this.assertAccess(scope);

    const [services, items, categories, pricing, mappings] = await Promise.all([
      this.repository.listServices(scope),
      this.repository.listItems(scope),
      this.repository.listCategories(scope),
      this.repository.listPricing(scope),
      this.repository.listMappings(scope, { status: CatalogStatus.ACTIVE }),
    ]);

    const activeServices = services.filter((s) => s.status === CatalogStatus.ACTIVE);
    const activeItems = items.filter((i) => i.status === CatalogStatus.ACTIVE);
    const activeCategories = categories.filter((c) => c.status === CatalogStatus.ACTIVE);

    const activeServiceIdSet = new Set(activeServices.map((s) => s.id));
    const activeItemIdSet = new Set(activeItems.map((i) => i.id));

    const activePricingRecords: SettingsPricingRecord[] = [...pricing];

    // Ensure every active mapped item/service pair has an active pricing entry
    for (const mapping of mappings) {
      if (
        activeServiceIdSet.has(mapping.serviceId) &&
        activeItemIdSet.has(mapping.itemCategoryId)
      ) {
        const hasPricing = activePricingRecords.some(
          (p) =>
            p.status === CatalogStatus.ACTIVE &&
            p.serviceId === mapping.serviceId &&
            p.itemCategoryId === mapping.itemCategoryId,
        );
        if (!hasPricing) {
          const service = activeServices.find((s) => s.id === mapping.serviceId);
          const created = await this.repository.createPricing(scope, {
            serviceId: mapping.serviceId,
            itemCategoryId: mapping.itemCategoryId,
            branchId: null,
            pricingType: mapping.pricingType ?? service?.pricingType ?? PricingType.PER_ITEM,
            basePrice: 0,
            taxPct: 0,
            effectiveFrom: new Date(),
            status: CatalogStatus.ACTIVE,
          });
          activePricingRecords.push(created);
        }
      }
    }

    // Ensure any active item without mappings gets associated with its matching or active service
    for (const item of activeItems) {
      const hasActiveMapping = mappings.some(
        (m) =>
          m.itemCategoryId === item.id &&
          activeServiceIdSet.has(m.serviceId) &&
          m.status === CatalogStatus.ACTIVE,
      );
      if (!hasActiveMapping && activeServices.length > 0) {
        const matchedService =
          activeServices.find(
            (s) =>
              s.serviceName.toLowerCase() === (item.category ?? '').toLowerCase() ||
              s.code.toLowerCase() === (item.category ?? '').toLowerCase(),
          ) ?? activeServices[0];

        await this.repository.createMapping(scope, {
          serviceId: matchedService.id,
          itemCategoryId: item.id,
          pricingType: matchedService.pricingType,
          status: CatalogStatus.ACTIVE,
          requiresPricingConfiguration: false,
        });

        const created = await this.repository.createPricing(scope, {
          serviceId: matchedService.id,
          itemCategoryId: item.id,
          branchId: null,
          pricingType: matchedService.pricingType,
          basePrice: 0,
          taxPct: 0,
          effectiveFrom: new Date(),
          status: CatalogStatus.ACTIVE,
        });
        activePricingRecords.push(created);
      }
    }

    // Deduplicate active pricing by serviceId and itemCategoryId
    const uniquePricingMap = new Map<string, SettingsPricingRecord>();
    for (const p of activePricingRecords) {
      if (
        p.status === CatalogStatus.ACTIVE &&
        activeServiceIdSet.has(p.serviceId) &&
        activeItemIdSet.has(p.itemCategoryId)
      ) {
        const key = `${p.serviceId}_${p.itemCategoryId}_${p.branchId ?? 'all'}`;
        if (!uniquePricingMap.has(key)) {
          uniquePricingMap.set(key, p);
        }
      }
    }
    const activePricing: SettingsPricingRecord[] = Array.from(uniquePricingMap.values());

    // Enrich items with active serviceIds from mappings and pricing
    const enrichedItems = items.map((item) => {
      const activeItemMappings = mappings.filter(
        (m) =>
          m.itemCategoryId === item.id &&
          activeServiceIdSet.has(m.serviceId) &&
          m.status === CatalogStatus.ACTIVE,
      );
      const activeItemPricing = activePricing.filter(
        (p: SettingsPricingRecord) => p.itemCategoryId === item.id,
      );
      const serviceIds = Array.from(
        new Set([
          ...(item.serviceIds ?? []),
          ...activeItemMappings.map((m) => m.serviceId),
          ...activeItemPricing.map((p: SettingsPricingRecord) => p.serviceId),
        ]),
      );
      return {
        ...item,
        serviceIds,
      };
    });

    return {
      tenantId: scope.tenantId,
      totalServices: services.length,
      totalActiveServices: activeServices.length,
      totalItems: items.length,
      totalActiveItems: activeItems.length,
      totalCategories: categories.length,
      totalActiveCategories: activeCategories.length,
      totalActivePricing: activePricing.length,
      services,
      items: enrichedItems,
      categories,
      pricing: activePricing,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // SERVICES
  // ─────────────────────────────────────────────────────────────────────────────
  async listServices(
    scope: SettingsScope,
    query?: SettingsQueryDto,
  ): Promise<readonly SettingsServiceRecord[]> {
    this.assertAccess(scope);
    return this.repository.listServices(scope, query);
  }

  async createService(
    scope: SettingsScope,
    input: CreateServiceSettingsDto,
  ): Promise<SettingsServiceRecord> {
    this.assertManage(scope);

    const code = input.code.toUpperCase().trim();
    const existing = await this.repository.findServiceByCode(scope, code);
    if (existing) {
      if (existing.status === CatalogStatus.INACTIVE) {
        const reactivated = await this.repository.updateService(scope, existing.id, {
          serviceName: input.serviceName.trim(),
          pricingType: input.pricingType,
          description: input.description?.trim(),
          categoryId: input.categoryId,
          status: CatalogStatus.ACTIVE,
        });
        if (reactivated) return reactivated;
      }
      throw new ConflictException(`Service with code "${code}" already exists for this tenant`);
    }

    const service = await this.repository.createService(scope, {
      serviceName: input.serviceName.trim(),
      code,
      pricingType: input.pricingType,
      description: input.description?.trim(),
      categoryId: input.categoryId,
      estimatedTimeMins: input.estimatedTimeMins,
      branchIds: input.branchIds ?? [],
      status: input.status ?? CatalogStatus.ACTIVE,
    });

    if (input.itemCategoryIds && input.itemCategoryIds.length > 0) {
      for (const itemCategoryId of input.itemCategoryIds) {
        const item = await this.repository.findItem(scope, itemCategoryId);
        if (item) {
          const mapping = await this.repository.findMapping(scope, service.id, item.id);
          if (!mapping) {
            await this.repository.createMapping(scope, {
              serviceId: service.id,
              itemCategoryId: item.id,
              pricingType: service.pricingType,
              status: CatalogStatus.ACTIVE,
              requiresPricingConfiguration: input.basePrice === undefined,
            });
          }

          if (input.basePrice !== undefined && input.basePrice >= 0) {
            await this.repository.createPricing(scope, {
              serviceId: service.id,
              itemCategoryId: item.id,
              branchId: null,
              pricingType: service.pricingType,
              basePrice: input.basePrice,
              taxPct: 0,
              effectiveFrom: new Date(),
              status: CatalogStatus.ACTIVE,
            });
          }
        }
      }
    }

    return service;
  }

  async updateService(
    scope: SettingsScope,
    id: string,
    input: UpdateServiceSettingsDto,
  ): Promise<SettingsServiceRecord> {
    this.assertManage(scope);

    const existing = await this.repository.findService(scope, id);
    if (!existing) throw new NotFoundException(`Service not found`);

    const updatePayload: Record<string, unknown> = {};
    if (input.serviceName !== undefined) updatePayload.serviceName = input.serviceName.trim();
    if (input.pricingType !== undefined) updatePayload.pricingType = input.pricingType;
    if (input.description !== undefined) updatePayload.description = input.description.trim();
    if (input.categoryId !== undefined) updatePayload.categoryId = input.categoryId;
    if (input.estimatedTimeMins !== undefined)
      updatePayload.estimatedTimeMins = input.estimatedTimeMins;
    if (input.branchIds !== undefined) updatePayload.branchIds = input.branchIds;
    if (input.status !== undefined) updatePayload.status = input.status;

    const updated = await this.repository.updateService(scope, id, updatePayload);
    if (!updated) throw new NotFoundException(`Service not found`);

    if (input.status === CatalogStatus.INACTIVE) {
      const servicePricings = await this.repository.listPricing(scope, { serviceId: id });
      for (const p of servicePricings) {
        if (p.status === CatalogStatus.ACTIVE) {
          await this.repository.updatePricing(scope, p.id, { status: CatalogStatus.INACTIVE });
        }
      }
      const mappings = await this.repository.listMappings(scope, { serviceId: id });
      for (const m of mappings) {
        if (m.status === CatalogStatus.ACTIVE) {
          await this.repository.updateMapping(scope, m.id, { status: CatalogStatus.INACTIVE });
        }
      }
    } else if (input.status === CatalogStatus.ACTIVE) {
      const mappings = await this.repository.listMappings(scope, { serviceId: id });
      for (const m of mappings) {
        if (m.status === CatalogStatus.INACTIVE) {
          await this.repository.updateMapping(scope, m.id, { status: CatalogStatus.ACTIVE });
        }
      }
      const servicePricings = await this.repository.listPricing(scope, { serviceId: id });
      for (const p of servicePricings) {
        if (p.status === CatalogStatus.INACTIVE) {
          await this.repository.updatePricing(scope, p.id, { status: CatalogStatus.ACTIVE });
        }
      }
    }

    return updated;
  }

  async deleteService(scope: SettingsScope, id: string): Promise<SettingsServiceRecord> {
    this.assertManage(scope);

    const existing = await this.repository.findService(scope, id);
    if (!existing) throw new NotFoundException(`Service not found`);

    // Safe soft-deactivation to preserve historical order integrity
    const updated = await this.repository.updateService(scope, id, {
      status: CatalogStatus.INACTIVE,
    });
    if (!updated) throw new NotFoundException(`Service not found`);

    const servicePricings = await this.repository.listPricing(scope, { serviceId: id });
    for (const p of servicePricings) {
      if (p.status === CatalogStatus.ACTIVE) {
        await this.repository.updatePricing(scope, p.id, { status: CatalogStatus.INACTIVE });
      }
    }

    const mappings = await this.repository.listMappings(scope, { serviceId: id });
    for (const m of mappings) {
      if (m.status === CatalogStatus.ACTIVE) {
        await this.repository.updateMapping(scope, m.id, { status: CatalogStatus.INACTIVE });
      }
    }

    return updated;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ITEMS
  // ─────────────────────────────────────────────────────────────────────────────
  async listItems(
    scope: SettingsScope,
    query?: SettingsQueryDto,
  ): Promise<readonly SettingsItemRecord[]> {
    this.assertAccess(scope);
    return this.repository.listItems(scope, query);
  }

  async createItem(
    scope: SettingsScope,
    input: CreateItemSettingsDto,
  ): Promise<SettingsItemRecord> {
    this.assertManage(scope);

    const code = input.code.toUpperCase().trim();
    const targetServiceIds =
      input.serviceIds && input.serviceIds.length > 0
        ? input.serviceIds
        : await this.resolveServiceIdsFromCategory(scope, input.category);

    const existing = await this.repository.findItemByCode(scope, code);
    if (existing) {
      if (targetServiceIds.length === 0) {
        if (existing.status === CatalogStatus.INACTIVE) {
          const reactivated = await this.repository.updateItem(scope, existing.id, {
            name: input.name.trim(),
            unitType: input.unitType,
            description: input.description?.trim(),
            category: input.category?.trim(),
            status: CatalogStatus.ACTIVE,
          });
          return reactivated ?? existing;
        }
        throw new ConflictException(`Item with code "${code}" already exists for this tenant`);
      }

      // Check if item is already actively mapped to ALL target services
      let allAlreadyActive = true;
      for (const serviceId of targetServiceIds) {
        const service = await this.repository.findService(scope, serviceId);
        if (service) {
          const mapping = await this.repository.findMapping(scope, service.id, existing.id);
          const pricings = await this.repository.listPricing(scope, {
            serviceId: service.id,
            itemCategoryId: existing.id,
          });
          const hasActivePrice = pricings.some((p) => p.status === CatalogStatus.ACTIVE);
          if (!mapping || mapping.status !== CatalogStatus.ACTIVE || !hasActivePrice) {
            allAlreadyActive = false;
          }
        }
      }

      if (allAlreadyActive && existing.status === CatalogStatus.ACTIVE) {
        const firstService = await this.repository.findService(scope, targetServiceIds[0]);
        throw new ConflictException(
          `Item "${existing.name}" is already associated with "${firstService?.serviceName ?? 'this service'}"`,
        );
      }

      // Ensure master item is Active
      if (existing.status !== CatalogStatus.ACTIVE) {
        await this.repository.updateItem(scope, existing.id, {
          name: input.name.trim(),
          unitType: input.unitType,
          description: input.description?.trim(),
          category: input.category?.trim(),
          status: CatalogStatus.ACTIVE,
        });
      }

      // Associate with target services (create/reactivate mapping and pricing)
      for (const serviceId of targetServiceIds) {
        const service = await this.repository.findService(scope, serviceId);
        if (service) {
          const mapping = await this.repository.findMapping(scope, service.id, existing.id);
          if (!mapping) {
            await this.repository.createMapping(scope, {
              serviceId: service.id,
              itemCategoryId: existing.id,
              pricingType: service.pricingType,
              status: CatalogStatus.ACTIVE,
              requiresPricingConfiguration: input.basePrice === undefined,
            });
          } else if (mapping.status !== CatalogStatus.ACTIVE) {
            await this.repository.updateMapping(scope, mapping.id, {
              status: CatalogStatus.ACTIVE,
              requiresPricingConfiguration: false,
            });
          }

          const pricings = await this.repository.listPricing(scope, {
            serviceId: service.id,
            itemCategoryId: existing.id,
          });
          const activePrice = pricings.find((p) => p.status === CatalogStatus.ACTIVE);
          if (!activePrice) {
            const inactivePrice = pricings.find((p) => p.status === CatalogStatus.INACTIVE);
            if (inactivePrice) {
              await this.repository.updatePricing(scope, inactivePrice.id, {
                status: CatalogStatus.ACTIVE,
                basePrice: input.basePrice ?? inactivePrice.basePrice,
              });
            } else {
              await this.repository.createPricing(scope, {
                serviceId: service.id,
                itemCategoryId: existing.id,
                branchId: null,
                pricingType: service.pricingType,
                basePrice: input.basePrice ?? 0,
                taxPct: 0,
                effectiveFrom: new Date(),
                status: CatalogStatus.ACTIVE,
              });
            }
          }
        }
      }

      return existing;
    }

    // Brand new item master record
    const item = await this.repository.createItem(scope, {
      name: input.name.trim(),
      code,
      unitType: input.unitType,
      description: input.description?.trim(),
      category: input.category?.trim(),
      catalogGroupCodes: input.catalogGroupCodes ?? [],
      branchIds: input.branchIds ?? [],
      status: input.status ?? CatalogStatus.ACTIVE,
    });

    for (const serviceId of targetServiceIds) {
      const service = await this.repository.findService(scope, serviceId);
      if (service) {
        const mapping = await this.repository.findMapping(scope, service.id, item.id);
        if (!mapping) {
          await this.repository.createMapping(scope, {
            serviceId: service.id,
            itemCategoryId: item.id,
            pricingType: service.pricingType,
            status: CatalogStatus.ACTIVE,
            requiresPricingConfiguration: input.basePrice === undefined,
          });
        }

        await this.repository.createPricing(scope, {
          serviceId: service.id,
          itemCategoryId: item.id,
          branchId: null,
          pricingType: service.pricingType,
          basePrice: input.basePrice ?? 0,
          taxPct: 0,
          effectiveFrom: new Date(),
          status: CatalogStatus.ACTIVE,
        });
      }
    }

    return item;
  }

  async updateItem(
    scope: SettingsScope,
    id: string,
    input: UpdateItemSettingsDto,
  ): Promise<SettingsItemRecord> {
    this.assertManage(scope);

    const existing = await this.repository.findItem(scope, id);
    if (!existing) throw new NotFoundException(`Item not found`);

    const updatePayload: Record<string, unknown> = {};
    if (input.name !== undefined) updatePayload.name = input.name.trim();
    if (input.unitType !== undefined) updatePayload.unitType = input.unitType;
    if (input.description !== undefined) updatePayload.description = input.description.trim();
    if (input.category !== undefined) updatePayload.category = input.category.trim();
    if (input.catalogGroupCodes !== undefined)
      updatePayload.catalogGroupCodes = input.catalogGroupCodes;
    if (input.branchIds !== undefined) updatePayload.branchIds = input.branchIds;
    if (input.status !== undefined) updatePayload.status = input.status;

    const updated = await this.repository.updateItem(scope, id, updatePayload);
    if (!updated) throw new NotFoundException(`Item not found`);

    if (input.status === CatalogStatus.INACTIVE) {
      const itemPricings = await this.repository.listPricing(scope, { itemCategoryId: id });
      for (const p of itemPricings) {
        if (p.status === CatalogStatus.ACTIVE) {
          await this.repository.updatePricing(scope, p.id, { status: CatalogStatus.INACTIVE });
        }
      }
      const mappings = await this.repository.listMappings(scope, { itemCategoryId: id });
      for (const m of mappings) {
        if (m.status === CatalogStatus.ACTIVE) {
          await this.repository.updateMapping(scope, m.id, { status: CatalogStatus.INACTIVE });
        }
      }
    } else if (input.status === CatalogStatus.ACTIVE) {
      const mappings = await this.repository.listMappings(scope, { itemCategoryId: id });
      for (const m of mappings) {
        if (m.status === CatalogStatus.INACTIVE) {
          await this.repository.updateMapping(scope, m.id, { status: CatalogStatus.ACTIVE });
        }
      }
      const itemPricings = await this.repository.listPricing(scope, { itemCategoryId: id });
      for (const p of itemPricings) {
        if (p.status === CatalogStatus.INACTIVE) {
          await this.repository.updatePricing(scope, p.id, { status: CatalogStatus.ACTIVE });
        }
      }
    }

    if (input.category && input.category.trim() !== existing.category) {
      const targetServiceIds = await this.resolveServiceIdsFromCategory(scope, input.category);
      for (const serviceId of targetServiceIds) {
        const service = await this.repository.findService(scope, serviceId);
        if (service) {
          const mapping = await this.repository.findMapping(scope, service.id, id);
          if (!mapping) {
            await this.repository.createMapping(scope, {
              serviceId: service.id,
              itemCategoryId: id,
              pricingType: service.pricingType,
              status: CatalogStatus.ACTIVE,
              requiresPricingConfiguration: true,
            });
          }
          const pricings = await this.repository.listPricing(scope, {
            serviceId: service.id,
            itemCategoryId: id,
          });
          if (!pricings.some((p) => p.status === CatalogStatus.ACTIVE)) {
            await this.repository.createPricing(scope, {
              serviceId: service.id,
              itemCategoryId: id,
              branchId: null,
              pricingType: service.pricingType,
              basePrice: 0,
              taxPct: 0,
              effectiveFrom: new Date(),
              status: CatalogStatus.ACTIVE,
            });
          }
        }
      }
    }

    return updated;
  }

  async deleteItem(scope: SettingsScope, id: string): Promise<SettingsItemRecord> {
    this.assertManage(scope);

    const existing = await this.repository.findItem(scope, id);
    if (!existing) throw new NotFoundException(`Item not found`);

    // Safe soft-deactivation
    const updated = await this.repository.updateItem(scope, id, {
      status: CatalogStatus.INACTIVE,
    });
    if (!updated) throw new NotFoundException(`Item not found`);

    const itemPricings = await this.repository.listPricing(scope, { itemCategoryId: id });
    for (const p of itemPricings) {
      if (p.status === CatalogStatus.ACTIVE) {
        await this.repository.updatePricing(scope, p.id, { status: CatalogStatus.INACTIVE });
      }
    }

    const mappings = await this.repository.listMappings(scope, { itemCategoryId: id });
    for (const m of mappings) {
      if (m.status === CatalogStatus.ACTIVE) {
        await this.repository.updateMapping(scope, m.id, { status: CatalogStatus.INACTIVE });
      }
    }

    return updated;
  }

  private async resolveServiceIdsFromCategory(
    scope: SettingsScope,
    categoryName?: string,
  ): Promise<string[]> {
    if (!categoryName || !categoryName.trim()) return [];
    const normalized = categoryName.trim().toLowerCase();
    const services = await this.repository.listServices(scope, { status: CatalogStatus.ACTIVE });
    const matched = services.filter(
      (s) =>
        s.serviceName.toLowerCase() === normalized ||
        s.code.toLowerCase() === normalized ||
        s.categoryId?.toLowerCase() === normalized,
    );
    return matched.map((s) => s.id);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────────────────────
  async listCategories(
    scope: SettingsScope,
    query?: SettingsQueryDto,
  ): Promise<readonly SettingsCategoryRecord[]> {
    this.assertAccess(scope);
    return this.repository.listCategories(scope, query);
  }

  async createCategory(
    scope: SettingsScope,
    input: CreateCategorySettingsDto,
  ): Promise<SettingsCategoryRecord> {
    this.assertManage(scope);

    const code = input.code.toUpperCase().trim();
    const existing = await this.repository.findCategoryByCode(scope, code);
    if (existing) {
      throw new ConflictException(`Category with code "${code}" already exists for this tenant`);
    }

    return this.repository.createCategory(scope, {
      name: input.name.trim(),
      code,
      description: input.description?.trim(),
      branchIds: input.branchIds ?? [],
      status: input.status ?? CatalogStatus.ACTIVE,
    });
  }

  async updateCategory(
    scope: SettingsScope,
    id: string,
    input: UpdateCategorySettingsDto,
  ): Promise<SettingsCategoryRecord> {
    this.assertManage(scope);

    const existing = await this.repository.findCategory(scope, id);
    if (!existing) throw new NotFoundException(`Category not found`);

    const updatePayload: Record<string, unknown> = {};
    if (input.name !== undefined) updatePayload.name = input.name.trim();
    if (input.description !== undefined) updatePayload.description = input.description.trim();
    if (input.branchIds !== undefined) updatePayload.branchIds = input.branchIds;
    if (input.status !== undefined) updatePayload.status = input.status;

    const updated = await this.repository.updateCategory(scope, id, updatePayload);
    if (!updated) throw new NotFoundException(`Category not found`);
    return updated;
  }

  async deleteCategory(scope: SettingsScope, id: string): Promise<SettingsCategoryRecord> {
    this.assertManage(scope);

    const existing = await this.repository.findCategory(scope, id);
    if (!existing) throw new NotFoundException(`Category not found`);

    // Safe soft-deactivation
    const updated = await this.repository.updateCategory(scope, id, {
      status: CatalogStatus.INACTIVE,
    });
    if (!updated) throw new NotFoundException(`Category not found`);
    return updated;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // PRICING
  // ─────────────────────────────────────────────────────────────────────────────
  async listPricing(
    scope: SettingsScope,
    filters?: { serviceId?: string; itemCategoryId?: string; branchId?: string },
  ): Promise<readonly SettingsPricingRecord[]> {
    this.assertAccess(scope);
    return this.repository.listPricing(scope, filters);
  }

  async updatePricing(
    scope: SettingsScope,
    id: string,
    input: UpdatePricingSettingsDto,
  ): Promise<SettingsPricingRecord> {
    this.assertManage(scope);

    const existing = await this.repository.findPricing(scope, id);
    if (!existing) throw new NotFoundException(`Pricing record not found`);

    if (input.basePrice < 0) {
      throw new BadRequestException('basePrice must be a non-negative number');
    }

    const updatePayload: Record<string, unknown> = {
      basePrice: input.basePrice,
      status: input.status ?? CatalogStatus.ACTIVE,
      effectiveFrom: input.effectiveFrom
        ? new Date(input.effectiveFrom)
        : (existing.effectiveFrom ?? new Date()),
      effectiveTo: input.effectiveTo ? new Date(input.effectiveTo) : null,
    };
    if (input.taxPct !== undefined) updatePayload.taxPct = input.taxPct;
    if (input.branchId !== undefined) updatePayload.branchId = input.branchId || null;

    const updated = await this.repository.updatePricing(scope, id, updatePayload);
    if (!updated) throw new NotFoundException(`Pricing record not found`);

    // Ensure active service mapping exists and is marked active for quote & order resolution
    const mapping = await this.repository.findMapping(
      scope,
      existing.serviceId,
      existing.itemCategoryId,
      existing.branchId,
    );
    if (!mapping) {
      const service = await this.repository.findService(scope, existing.serviceId);
      await this.repository.createMapping(scope, {
        serviceId: existing.serviceId,
        itemCategoryId: existing.itemCategoryId,
        branchId: existing.branchId ?? null,
        pricingType: service?.pricingType ?? PricingType.PER_ITEM,
        status: CatalogStatus.ACTIVE,
        requiresPricingConfiguration: false,
      });
    } else if (mapping.status !== CatalogStatus.ACTIVE || mapping.requiresPricingConfiguration) {
      await this.repository.updateMapping(scope, mapping.id, {
        status: CatalogStatus.ACTIVE,
        requiresPricingConfiguration: false,
      });
    }

    return updated;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // AUTHORIZATION HELPERS
  // ─────────────────────────────────────────────────────────────────────────────
  private assertAccess(scope: SettingsScope): void {
    if (
      !isOwnerRole(scope.roleCode) &&
      !isBranchManagerRole(scope.roleCode) &&
      !hasPermission(scope.roleCode, scope.permissions, Permissions.businessSettingsWrite)
    ) {
      throw new ForbiddenException('Only Owners and Branch Managers can access Business Settings');
    }
  }

  private assertManage(scope: SettingsScope): void {
    if (
      !isOwnerRole(scope.roleCode) &&
      !hasPermission(scope.roleCode, scope.permissions, Permissions.businessSettingsWrite)
    ) {
      throw new ForbiddenException(
        'Only Owners and authorized Managers can manage Business Settings',
      );
    }
  }
}
