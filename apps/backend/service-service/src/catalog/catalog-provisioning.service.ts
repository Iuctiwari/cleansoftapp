import { ConflictException, Inject, Injectable, ServiceUnavailableException } from '@nestjs/common';

import { CatalogService } from './catalog.service';
import {
  CATALOG_REPOSITORY,
  type CatalogBusinessType,
  type CatalogRepository,
  type CatalogScope,
  type CatalogTemplateRecord,
  type ItemCategoryRecord,
  type ServiceMappingRecord,
  type ServiceRecord,
} from './catalog.types';

export interface CatalogProvisioningResult {
  readonly tenantId: string;
  readonly appliedTemplates: readonly string[];
  readonly missingTemplates: readonly CatalogBusinessType[];
  readonly createdItems: number;
  readonly reusedItems: number;
  readonly createdServices: number;
  readonly reusedServices: number;
  readonly createdMappings: number;
  readonly reusedMappings: number;
  readonly createdPrices: number;
  readonly preservedPrices: number;
  readonly pricingConfigurationRequired: number;
}

@Injectable()
export class CatalogProvisioningService {
  constructor(
    private readonly catalog: CatalogService,
    @Inject(CATALOG_REPOSITORY) private readonly repository: CatalogRepository,
  ) {}

  async provision(input: {
    tenantId: string;
    actorId: string;
    businessTypes: readonly CatalogBusinessType[];
  }): Promise<CatalogProvisioningResult> {
    const businessTypes = [...new Set(input.businessTypes)];
    const templates = await this.repository.listTemplatesByBusinessTypes(businessTypes);
    const foundTypes = new Set(templates.map((template) => template.businessType));
    const missingTemplates = businessTypes.filter((type) => !foundTypes.has(type));
    if (missingTemplates.length > 0) {
      throw new ServiceUnavailableException(
        `Catalog templates are not installed for: ${missingTemplates.join(', ')}`,
      );
    }
    const scope = this.scope(input.tenantId, input.actorId);
    const items = new Map<string, ItemCategoryRecord>();
    const services = new Map<string, ServiceRecord>();
    let createdItems = 0;
    let reusedItems = 0;
    let createdServices = 0;
    let reusedServices = 0;
    let createdMappings = 0;
    let reusedMappings = 0;
    let createdPrices = 0;
    let preservedPrices = 0;

    const itemDefinitions = new Map<
      string,
      {
        definition: CatalogTemplateRecord['items'][number];
        catalogGroupCodes: Set<string>;
      }
    >();
    for (const template of templates) {
      for (const item of template.items) {
        const existing = itemDefinitions.get(item.code);
        if (existing) {
          existing.catalogGroupCodes.add(template.code);
        } else {
          itemDefinitions.set(item.code, {
            definition: item,
            catalogGroupCodes: new Set([template.code]),
          });
        }
      }
    }
    const serviceDefinitions = new Map(
      templates.flatMap((template) =>
        template.services.map((service) => [service.code, service] as const),
      ),
    );
    await Promise.all([
      ...[...itemDefinitions.values()].map(async ({ definition, catalogGroupCodes }) => {
        const result = await this.item(scope, definition, [...catalogGroupCodes].sort());
        items.set(definition.code, result.record);
        if (result.created) createdItems++;
        else reusedItems++;
      }),
      ...[...serviceDefinitions.values()].map(async (service) => {
        const result = await this.service(scope, service);
        services.set(service.code, result.record);
        if (result.created) createdServices++;
        else reusedServices++;
      }),
    ]);

    const mappings = new Map<string, ServiceMappingRecord>();
    const mappingDefinitions = new Map<
      string,
      { itemId: string; serviceId: string; requiresPricingConfiguration: boolean }
    >();
    for (const template of templates) {
      for (const definition of template.mappings) {
        const item = items.get(definition.itemCode);
        const service = services.get(definition.serviceCode);
        if (!item || !service) continue;
        const key = `${item.id}:${service.id}`;
        mappingDefinitions.set(key, {
          itemId: item.id,
          serviceId: service.id,
          requiresPricingConfiguration: definition.requiresPricingConfiguration,
        });
      }
    }
    await Promise.all(
      [...mappingDefinitions.entries()].map(async ([key, definition]) => {
        const result = await this.mapping(
          scope,
          definition.itemId,
          definition.serviceId,
          definition.requiresPricingConfiguration,
        );
        mappings.set(key, result.record);
        if (result.created) createdMappings++;
        else reusedMappings++;
      }),
    );

    const priceDefinitions = new Map<
      string,
      CatalogTemplateRecord['pricing'][number] & { itemId: string; serviceId: string }
    >();
    for (const template of templates) {
      for (const price of template.pricing) {
        const item = items.get(price.itemCode);
        const service = services.get(price.serviceCode);
        if (!item || !service) continue;
        const key = `${item.id}:${service.id}`;
        const existing = priceDefinitions.get(key);
        if (
          existing &&
          (existing.basePrice !== price.basePrice || existing.taxPct !== price.taxPct)
        ) {
          throw new ConflictException(
            `Conflicting predefined pricing for ${price.itemCode} + ${price.serviceCode}`,
          );
        }
        priceDefinitions.set(key, { ...price, itemId: item.id, serviceId: service.id });
      }
    }
    const configuredMappings = new Set<string>();
    await Promise.all(
      [...priceDefinitions.entries()].map(async ([key, price]) => {
        if (await this.repository.hasAnyTenantWidePricing(scope, price.serviceId, price.itemId)) {
          preservedPrices++;
          configuredMappings.add(key);
          const mapping = mappings.get(key);
          if (mapping?.requiresPricingConfiguration) {
            await this.repository.updateMapping(scope, mapping.id, {
              requiresPricingConfiguration: false,
            });
          }
          return;
        }
        try {
          await this.catalog.createPricing(scope, price.serviceId, {
            itemCategoryId: price.itemId,
            basePrice: price.basePrice,
            taxPct: price.taxPct,
            effectiveFrom: price.effectiveFrom.toISOString(),
          });
          createdPrices++;
          configuredMappings.add(key);
        } catch (error) {
          if (!(error instanceof ConflictException)) throw error;
          preservedPrices++;
          configuredMappings.add(key);
        }
      }),
    );

    const pricingConfigurationRequired = [...mappings.values()].filter(
      (mapping) =>
        mapping.requiresPricingConfiguration &&
        !configuredMappings.has(`${mapping.itemCategoryId}:${mapping.serviceId}`),
    ).length;
    return {
      tenantId: input.tenantId,
      appliedTemplates: templates.map((template) => template.code),
      missingTemplates,
      createdItems,
      reusedItems,
      createdServices,
      reusedServices,
      createdMappings,
      reusedMappings,
      createdPrices,
      preservedPrices,
      pricingConfigurationRequired,
    };
  }

  private async item(
    scope: CatalogScope,
    definition: {
      code: string;
      name: string;
      unitType: Parameters<CatalogService['createItemCategory']>[1]['unitType'];
      description?: string;
    },
    catalogGroupCodes: readonly string[],
  ): Promise<{ record: ItemCategoryRecord; created: boolean }> {
    const existing = await this.repository.findItemCategoryByCode(scope, definition.code);
    if (existing) {
      const mergedGroupCodes = [
        ...new Set([...existing.catalogGroupCodes, ...catalogGroupCodes]),
      ].sort();
      if (mergedGroupCodes.join('\u0000') === existing.catalogGroupCodes.join('\u0000')) {
        return { record: existing, created: false };
      }
      const updated = await this.repository.updateItemCategory(scope, existing.id, {
        catalogGroupCodes: mergedGroupCodes,
      });
      if (!updated) throw new ConflictException('Catalog item grouping update conflicted');
      return { record: updated, created: false };
    }
    try {
      const created = await this.catalog.createItemCategory(scope, {
        ...definition,
        branchIds: [],
      });
      const grouped = await this.repository.updateItemCategory(scope, created.id, {
        catalogGroupCodes,
      });
      if (!grouped) throw new ConflictException('Catalog item grouping update conflicted');
      return { record: grouped, created: true };
    } catch (error) {
      if (!(error instanceof ConflictException)) throw error;
      const raced = await this.repository.findItemCategoryByCode(scope, definition.code);
      if (!raced) throw error;
      const mergedGroupCodes = [
        ...new Set([...raced.catalogGroupCodes, ...catalogGroupCodes]),
      ].sort();
      const grouped = await this.repository.updateItemCategory(scope, raced.id, {
        catalogGroupCodes: mergedGroupCodes,
      });
      if (!grouped) throw error;
      return { record: grouped, created: false };
    }
  }

  private async service(
    scope: CatalogScope,
    definition: {
      code: string;
      name: string;
      pricingType: Parameters<CatalogService['createService']>[1]['pricingType'];
      description?: string;
    },
  ): Promise<{ record: ServiceRecord; created: boolean }> {
    const existing = await this.repository.findServiceByCode(scope, definition.code);
    if (existing) return { record: existing, created: false };
    try {
      return {
        record: await this.catalog.createService(scope, { ...definition, branchIds: [] }),
        created: true,
      };
    } catch (error) {
      if (!(error instanceof ConflictException)) throw error;
      const raced = await this.repository.findServiceByCode(scope, definition.code);
      if (!raced) throw error;
      return { record: raced, created: false };
    }
  }

  private async mapping(
    scope: CatalogScope,
    itemCategoryId: string,
    serviceId: string,
    requiresPricingConfiguration: boolean,
  ): Promise<{ record: ServiceMappingRecord; created: boolean }> {
    const existing = await this.repository.findTenantWideMapping(scope, serviceId, itemCategoryId);
    if (existing) return { record: existing, created: false };
    try {
      return {
        record: await this.catalog.createMapping(scope, {
          itemCategoryId,
          serviceId,
          requiresPricingConfiguration,
        }),
        created: true,
      };
    } catch (error) {
      if (!(error instanceof ConflictException)) throw error;
      const raced = await this.repository.findTenantWideMapping(scope, serviceId, itemCategoryId);
      if (!raced) throw error;
      return { record: raced, created: false };
    }
  }

  private scope(tenantId: string, actorId: string): CatalogScope {
    return {
      tenantId,
      actorId,
      branchId: 'tenant-wide-provisioning',
      authorization: 'Internal tenant-service catalog provisioning',
      permissions: [],
      roleCode: 'tenant_owner',
    };
  }
}
