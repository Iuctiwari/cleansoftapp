/* eslint-disable @typescript-eslint/unbound-method */
import { BadRequestException } from '@nestjs/common';

import { CatalogStatus, PricingType, UnitType } from '../src/settings/enums';
import { SettingsProvisioningService } from '../src/settings/settings-provisioning.service';
import type {
  SettingsItemRecord,
  SettingsRepository,
  SettingsScope,
  SettingsServiceRecord,
} from '../src/settings/settings.types';

describe('SettingsProvisioningService', () => {
  const tenantId = '64f0c18f7c4d2f0012ab3400';
  const actorId = '64f0c18f7c4d2f0012ab3401';

  let repository: jest.Mocked<SettingsRepository>;
  let provisioningService: SettingsProvisioningService;

  beforeEach(() => {
    repository = {
      listServices: jest.fn().mockResolvedValue([]),
      findService: jest.fn().mockResolvedValue(null),
      findServiceByCode: jest.fn().mockResolvedValue(null),
      createService: jest
        .fn()
        .mockImplementation((scope: SettingsScope, input: Record<string, unknown>) =>
          Promise.resolve({
            id: `svc_${input.code as string}`,
            tenantId: scope.tenantId,
            serviceName: input.serviceName as string,
            name: input.serviceName as string,
            code: input.code as string,
            pricingType: input.pricingType as PricingType,
            branchIds: [],
            status: CatalogStatus.ACTIVE,
            createdAt: new Date(),
            updatedAt: new Date(),
            version: 1,
          }),
        ),
      updateService: jest.fn().mockResolvedValue(null),

      listItems: jest.fn().mockResolvedValue([]),
      findItem: jest.fn().mockResolvedValue(null),
      findItemByCode: jest.fn().mockResolvedValue(null),
      createItem: jest
        .fn()
        .mockImplementation((scope: SettingsScope, input: Record<string, unknown>) =>
          Promise.resolve({
            id: `item_${input.code as string}`,
            tenantId: scope.tenantId,
            name: input.name as string,
            code: input.code as string,
            unitType: input.unitType as UnitType,
            catalogGroupCodes: (input.catalogGroupCodes as string[]) ?? [],
            branchIds: [],
            status: CatalogStatus.ACTIVE,
            createdAt: new Date(),
            updatedAt: new Date(),
            version: 1,
          }),
        ),
      updateItem: jest.fn().mockResolvedValue(null),

      listCategories: jest.fn().mockResolvedValue([]),
      findCategory: jest.fn().mockResolvedValue(null),
      findCategoryByCode: jest.fn().mockResolvedValue(null),
      createCategory: jest.fn().mockResolvedValue({
        id: 'cat_default',
        tenantId,
        name: 'Default',
        code: 'DEFAULT',
        branchIds: [],
        status: CatalogStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        version: 1,
      }),
      updateCategory: jest.fn().mockResolvedValue(null),

      listPricing: jest.fn().mockResolvedValue([]),
      findPricing: jest.fn().mockResolvedValue(null),
      createPricing: jest
        .fn()
        .mockImplementation((scope: SettingsScope, input: Record<string, unknown>) =>
          Promise.resolve({
            id: `price_${input.serviceId as string}_${input.itemCategoryId as string}`,
            tenantId: scope.tenantId,
            serviceId: input.serviceId as string,
            itemCategoryId: input.itemCategoryId as string,
            branchId: null,
            pricingType: input.pricingType as PricingType,
            basePrice: input.basePrice as number,
            taxPct: (input.taxPct as number) ?? 0,
            effectiveFrom: (input.effectiveFrom as Date) ?? new Date(),
            status: CatalogStatus.ACTIVE,
            createdAt: new Date(),
            updatedAt: new Date(),
            version: 1,
          }),
        ),
      updatePricing: jest.fn().mockResolvedValue(null),

      listMappings: jest.fn().mockResolvedValue([]),
      findMapping: jest.fn().mockResolvedValue(null),
      createMapping: jest
        .fn()
        .mockImplementation((scope: SettingsScope, input: Record<string, unknown>) =>
          Promise.resolve({
            id: `map_${input.serviceId as string}_${input.itemCategoryId as string}`,
            tenantId: scope.tenantId,
            serviceId: input.serviceId as string,
            itemCategoryId: input.itemCategoryId as string,
            branchId: null,
            pricingType: input.pricingType as PricingType,
            requiresPricingConfiguration: false,
            status: CatalogStatus.ACTIVE,
            createdAt: new Date(),
            updatedAt: new Date(),
            version: 1,
          }),
        ),
      updateMapping: jest.fn().mockResolvedValue(null),
    };

    provisioningService = new SettingsProvisioningService(repository);
  });

  describe('DRY_CLEANING Onboarding Initialization', () => {
    it('initializes only Dry Cleaning template items, services, mappings, and pricing for the tenant', async () => {
      const result = await provisioningService.initializeTenantSettings({
        tenantId,
        actorId,
        businessType: 'DRY_CLEANING',
      });

      expect(result.tenantId).toBe(tenantId);
      expect(result.appliedTemplate).toBe('DRY_CLEANING');
      expect(result.createdItems).toBe(7); // Shirt, Trouser, Suit, Jacket, Carpet, Shoes, Blanket
      expect(result.createdServices).toBe(4); // Dry Cleaning, Wash & Fold, Ironing, Premium Cleaning
      expect(result.createdMappings).toBe(28); // 7 items * 4 services
      expect(result.createdPrices).toBe(28);

      // Verify that all created items belong to this tenantId
      expect(repository.createItem).toHaveBeenCalledWith(
        expect.objectContaining({ tenantId, actorId }),
        expect.objectContaining({ code: 'ITEM_SHIRT', name: 'Shirt' }),
      );

      // Verify that all created services belong to this tenantId
      expect(repository.createService).toHaveBeenCalledWith(
        expect.objectContaining({ tenantId, actorId }),
        expect.objectContaining({ code: 'SERVICE_DRY_CLEANING', serviceName: 'Dry Cleaning' }),
      );
    });
  });

  describe('LAUNDRY Onboarding Initialization', () => {
    it('initializes only Laundry template items and services without loading salon or car wash', async () => {
      const result = await provisioningService.initializeTenantSettings({
        tenantId,
        actorId,
        businessType: 'laundry',
      });

      expect(result.tenantId).toBe(tenantId);
      expect(result.appliedTemplate).toBe('LAUNDRY');
      expect(result.createdItems).toBe(5); // Shirt, Trouser, Blanket, Bedsheet, Curtain
      expect(result.createdServices).toBe(3); // Wash & Fold, Ironing, Wash Only

      // Verify no salon or car wash items were created
      expect(repository.createItem).not.toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ code: 'SALON_HAIR' }),
      );
      expect(repository.createItem).not.toHaveBeenCalledWith(
        expect.anything(),
        expect.objectContaining({ code: 'VEHICLE_SEDAN' }),
      );
    });
  });

  describe('CAR_WASH Onboarding Initialization', () => {
    it('initializes only vehicle wash template items and services', async () => {
      const result = await provisioningService.initializeTenantSettings({
        tenantId,
        actorId,
        businessType: 'CAR_WASH',
      });

      expect(result.appliedTemplate).toBe('CAR_WASH');
      expect(result.createdItems).toBe(4); // Hatchback, Sedan, SUV, Bike
      expect(result.createdServices).toBe(3); // Interior, Exterior, Full Wash
    });
  });

  describe('Idempotency & Retry Safety', () => {
    it('prevents duplicate initialization when onboarding is retried', async () => {
      const existingItem: SettingsItemRecord = {
        id: 'item_ITEM_SHIRT',
        tenantId,
        name: 'Shirt',
        code: 'ITEM_SHIRT',
        unitType: UnitType.PIECE,
        catalogGroupCodes: ['DRY_CLEANING'],
        branchIds: [],
        status: CatalogStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        version: 1,
      };

      const existingService: SettingsServiceRecord = {
        id: 'svc_SERVICE_DRY_CLEANING',
        tenantId,
        serviceName: 'Dry Cleaning',
        name: 'Dry Cleaning',
        code: 'SERVICE_DRY_CLEANING',
        pricingType: PricingType.PER_ITEM,
        branchIds: [],
        status: CatalogStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        version: 1,
      };

      repository.findItemByCode.mockResolvedValue(existingItem);
      repository.findServiceByCode.mockResolvedValue(existingService);
      repository.findMapping.mockResolvedValue({
        id: 'map_existing',
        tenantId,
        serviceId: existingService.id,
        itemCategoryId: existingItem.id,
        branchId: null,
        pricingType: PricingType.PER_ITEM,
        requiresPricingConfiguration: false,
        status: CatalogStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        version: 1,
      });
      repository.listPricing.mockResolvedValue([
        {
          id: 'price_existing',
          tenantId,
          serviceId: existingService.id,
          itemCategoryId: existingItem.id,
          branchId: null,
          pricingType: PricingType.PER_ITEM,
          basePrice: 100,
          taxPct: 0,
          effectiveFrom: new Date(),
          status: CatalogStatus.ACTIVE,
          createdAt: new Date(),
          updatedAt: new Date(),
          version: 1,
        },
      ]);

      const result = await provisioningService.initializeTenantSettings({
        tenantId,
        actorId,
        businessType: 'DRY_CLEANING',
      });

      expect(result.createdItems).toBe(0);
      expect(result.createdServices).toBe(0);
      expect(result.createdMappings).toBe(0);
      expect(result.createdPrices).toBe(0);
      expect(repository.createItem).not.toHaveBeenCalled();
      expect(repository.createService).not.toHaveBeenCalled();
    });
  });

  describe('Error Handling', () => {
    it('rejects unsupported business templates with BadRequestException', async () => {
      await expect(
        provisioningService.initializeTenantSettings({
          tenantId,
          actorId,
          businessType: 'UNKNOWN_BUSINESS_TYPE_999',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
