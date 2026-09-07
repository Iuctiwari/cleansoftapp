import { BadRequestException, Inject, Injectable } from '@nestjs/common';

import type {
  InitializeTenantSettingsDto,
  InitializeTenantSettingsResponseDto,
} from './dtos/initialize-settings.dto';
import { CatalogStatus } from './enums';
import { findTemplateByBusinessType } from './settings-template.seed-data';
import {
  SETTINGS_REPOSITORY,
  type SettingsItemRecord,
  type SettingsRepository,
  type SettingsScope,
  type SettingsServiceRecord,
} from './settings.types';

@Injectable()
export class SettingsProvisioningService {
  constructor(
    @Inject(SETTINGS_REPOSITORY)
    private readonly repository: SettingsRepository,
  ) {}

  async initializeTenantSettings(
    input: InitializeTenantSettingsDto,
  ): Promise<InitializeTenantSettingsResponseDto> {
    const template = findTemplateByBusinessType(input.businessType);
    if (!template) {
      throw new BadRequestException(
        `Catalog template not found for business type "${input.businessType}"`,
      );
    }

    const scope: SettingsScope = {
      actorId: input.actorId,
      authorization: '',
      branchId: 'default',
      permissions: ['*'],
      roleCode: 'Owner',
      tenantId: input.tenantId,
    };

    const itemsMap = new Map<string, SettingsItemRecord>();
    const servicesMap = new Map<string, SettingsServiceRecord>();
    let createdItems = 0;
    let createdServices = 0;
    let createdMappings = 0;
    let createdPrices = 0;

    // 1. Initialize / Copy Items
    for (const itemDef of template.items) {
      let item = await this.repository.findItemByCode(scope, itemDef.code);
      if (!item) {
        item = await this.repository.createItem(scope, {
          name: itemDef.name,
          code: itemDef.code,
          unitType: itemDef.unitType,
          description: itemDef.description,
          category: template.name,
          catalogGroupCodes: [template.code],
          branchIds: [],
          status: CatalogStatus.ACTIVE,
        });
        createdItems++;
      }
      itemsMap.set(itemDef.code, item);
    }

    // 2. Initialize / Copy Services
    for (const serviceDef of template.services) {
      let service = await this.repository.findServiceByCode(scope, serviceDef.code);
      if (!service) {
        service = await this.repository.createService(scope, {
          serviceName: serviceDef.name,
          code: serviceDef.code,
          pricingType: serviceDef.pricingType,
          description: serviceDef.description,
          branchIds: [],
          status: CatalogStatus.ACTIVE,
        });
        createdServices++;
      }
      servicesMap.set(serviceDef.code, service);
    }

    // 3. Initialize / Copy Mappings
    for (const mappingDef of template.mappings) {
      const item = itemsMap.get(mappingDef.itemCode);
      const service = servicesMap.get(mappingDef.serviceCode);
      if (!item || !service) continue;

      const existingMapping = await this.repository.findMapping(scope, service.id, item.id);
      if (!existingMapping) {
        await this.repository.createMapping(scope, {
          serviceId: service.id,
          itemCategoryId: item.id,
          branchId: null,
          pricingType: service.pricingType,
          requiresPricingConfiguration: mappingDef.requiresPricingConfiguration,
          status: CatalogStatus.ACTIVE,
        });
        createdMappings++;
      }
    }

    // 4. Initialize / Copy Base Pricing
    for (const priceDef of template.pricing) {
      const item = itemsMap.get(priceDef.itemCode);
      const service = servicesMap.get(priceDef.serviceCode);
      if (!item || !service) continue;

      const existingPricing = await this.repository.listPricing(scope, {
        serviceId: service.id,
        itemCategoryId: item.id,
      });

      if (existingPricing.length === 0) {
        await this.repository.createPricing(scope, {
          serviceId: service.id,
          itemCategoryId: item.id,
          branchId: null,
          pricingType: service.pricingType,
          basePrice: priceDef.basePrice,
          taxPct: priceDef.taxPct,
          effectiveFrom: priceDef.effectiveFrom,
          status: CatalogStatus.ACTIVE,
        });
        createdPrices++;
      }
    }

    return {
      tenantId: input.tenantId,
      businessType: input.businessType,
      appliedTemplate: template.code,
      createdItems,
      createdServices,
      createdMappings,
      createdPrices,
    };
  }
}
