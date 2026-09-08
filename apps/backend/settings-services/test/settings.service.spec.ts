/* eslint-disable @typescript-eslint/unbound-method */
import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';

import { CatalogStatus, PricingType, UnitType } from '../src/settings/enums';
import { SettingsServicePricingMongooseSchema } from '../src/settings/settings.schema';
import { SettingsService } from '../src/settings/settings.service';
import type {
  SettingsCategoryRecord,
  SettingsItemRecord,
  SettingsPricingRecord,
  SettingsRepository,
  SettingsScope,
  SettingsServiceRecord,
} from '../src/settings/settings.types';

describe('SettingsService', () => {
  const scope: SettingsScope = {
    actorId: '64f0c18f7c4d2f0012ab3401',
    authorization: 'Bearer token',
    branchId: '64f0c18f7c4d2f0012ab3402',
    permissions: ['*'],
    roleCode: 'Owner',
    tenantId: '64f0c18f7c4d2f0012ab3400',
  };

  const mockServiceRecord: SettingsServiceRecord = {
    id: '64f0c18f7c4d2f0012ab3410',
    tenantId: scope.tenantId,
    serviceName: 'Dry Cleaning',
    name: 'Dry Cleaning',
    code: 'DRY_CLEAN',
    pricingType: PricingType.PER_ITEM,
    branchIds: [],
    status: CatalogStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
    version: 1,
  };

  const mockItemRecord: SettingsItemRecord = {
    id: '64f0c18f7c4d2f0012ab3420',
    tenantId: scope.tenantId,
    name: 'Silk Shirt',
    code: 'SILK_SHIRT',
    unitType: UnitType.PIECE,
    catalogGroupCodes: [],
    branchIds: [],
    status: CatalogStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
    version: 1,
  };

  const mockCategoryRecord: SettingsCategoryRecord = {
    id: '64f0c18f7c4d2f0012ab3430',
    tenantId: scope.tenantId,
    name: 'Garments',
    code: 'GARMENTS',
    branchIds: [],
    status: CatalogStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
    version: 1,
  };

  const mockPricingRecord: SettingsPricingRecord = {
    id: '64f0c18f7c4d2f0012ab3440',
    tenantId: scope.tenantId,
    serviceId: mockServiceRecord.id,
    itemCategoryId: mockItemRecord.id,
    branchId: null,
    pricingType: PricingType.PER_ITEM,
    basePrice: 15.0,
    taxPct: 5.0,
    effectiveFrom: new Date(),
    status: CatalogStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
    version: 1,
  };

  let repository: jest.Mocked<SettingsRepository>;
  let service: SettingsService;

  beforeEach(() => {
    repository = {
      listServices: jest.fn().mockResolvedValue([mockServiceRecord]),
      findService: jest.fn().mockResolvedValue(mockServiceRecord),
      findServiceByCode: jest.fn().mockResolvedValue(null),
      createService: jest.fn().mockResolvedValue(mockServiceRecord),
      updateService: jest
        .fn()
        .mockImplementation((_scope, _id, input) =>
          Promise.resolve({ ...mockServiceRecord, ...input }),
        ),

      listItems: jest.fn().mockResolvedValue([mockItemRecord]),
      findItem: jest.fn().mockResolvedValue(mockItemRecord),
      findItemByCode: jest.fn().mockResolvedValue(null),
      createItem: jest.fn().mockResolvedValue(mockItemRecord),
      updateItem: jest
        .fn()
        .mockImplementation((_scope, _id, input) =>
          Promise.resolve({ ...mockItemRecord, ...input }),
        ),

      listCategories: jest.fn().mockResolvedValue([mockCategoryRecord]),
      findCategory: jest.fn().mockResolvedValue(mockCategoryRecord),
      findCategoryByCode: jest.fn().mockResolvedValue(null),
      createCategory: jest.fn().mockResolvedValue(mockCategoryRecord),
      updateCategory: jest
        .fn()
        .mockImplementation((_scope, _id, input) =>
          Promise.resolve({ ...mockCategoryRecord, ...input }),
        ),

      listPricing: jest.fn().mockResolvedValue([mockPricingRecord]),
      findPricing: jest.fn().mockResolvedValue(mockPricingRecord),
      createPricing: jest.fn().mockResolvedValue(mockPricingRecord),
      updatePricing: jest
        .fn()
        .mockImplementation((_scope, _id, input) =>
          Promise.resolve({ ...mockPricingRecord, ...input }),
        ),

      listMappings: jest.fn().mockResolvedValue([]),
      createMapping: jest.fn().mockResolvedValue({
        id: '64f0c18f7c4d2f0012ab3450',
        tenantId: scope.tenantId,
        serviceId: mockServiceRecord.id,
        itemCategoryId: mockItemRecord.id,
        branchId: null,
        pricingType: PricingType.PER_ITEM,
        requiresPricingConfiguration: false,
        status: CatalogStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        version: 1,
      }),
      updateMapping: jest.fn().mockResolvedValue(null),
      findMapping: jest.fn().mockResolvedValue(null),
    };

    service = new SettingsService(repository);
  });

  describe('getBusinessCatalogSettings', () => {
    it('returns full tenant catalog summary with counts and collections', async () => {
      const summary = await service.getBusinessCatalogSettings(scope);

      expect(summary.tenantId).toBe(scope.tenantId);
      expect(summary.totalServices).toBe(1);
      expect(summary.totalActiveServices).toBe(1);
      expect(summary.totalItems).toBe(1);
      expect(summary.totalActiveItems).toBe(1);
      expect(summary.totalCategories).toBe(1);
      expect(summary.totalActiveCategories).toBe(1);
      expect(summary.totalActivePricing).toBe(1);
      expect(summary.services).toEqual([mockServiceRecord]);
      expect(summary.items).toEqual([{ ...mockItemRecord, serviceIds: [mockServiceRecord.id] }]);
      expect(summary.categories).toEqual([mockCategoryRecord]);
      expect(summary.pricing).toEqual([mockPricingRecord]);
    });

    it('rejects non-owner / non-manager roles', async () => {
      const staffScope = { ...scope, roleCode: 'Staff' };
      await expect(service.getBusinessCatalogSettings(staffScope)).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('Services Management', () => {
    it('creates a service and validates code uniqueness', async () => {
      const result = await service.createService(scope, {
        serviceName: 'Laundry',
        code: 'LAUNDRY',
        pricingType: PricingType.PER_KG,
      });

      expect(repository.findServiceByCode).toHaveBeenCalledWith(scope, 'LAUNDRY');
      expect(repository.createService).toHaveBeenCalled();
      expect(result.id).toBe(mockServiceRecord.id);
    });

    it('rejects duplicate service code within the tenant', async () => {
      repository.findServiceByCode.mockResolvedValueOnce(mockServiceRecord);

      await expect(
        service.createService(scope, {
          serviceName: 'Dry Cleaning',
          code: 'DRY_CLEAN',
          pricingType: PricingType.PER_ITEM,
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('safely deactivates a service on delete without destroying historical data', async () => {
      const result = await service.deleteService(scope, mockServiceRecord.id);

      expect(repository.updateService).toHaveBeenCalledWith(scope, mockServiceRecord.id, {
        status: CatalogStatus.INACTIVE,
      });
      expect(result.status).toBe(CatalogStatus.INACTIVE);
    });
  });

  describe('Items Management', () => {
    it('creates an item and validates code uniqueness', async () => {
      const result = await service.createItem(scope, {
        name: 'Cotton Pants',
        code: 'COTTON_PANTS',
        unitType: UnitType.PIECE,
      });

      expect(repository.findItemByCode).toHaveBeenCalledWith(scope, 'COTTON_PANTS');
      expect(repository.createItem).toHaveBeenCalled();
      expect(result.id).toBe(mockItemRecord.id);
    });

    it('rejects duplicate active item code on the same service', async () => {
      repository.findItemByCode.mockResolvedValueOnce(mockItemRecord);
      repository.findMapping.mockResolvedValueOnce({
        id: '64f0c18f7c4d2f0012ab3450',
        tenantId: scope.tenantId,
        serviceId: mockServiceRecord.id,
        itemCategoryId: mockItemRecord.id,
        branchId: null,
        pricingType: PricingType.PER_ITEM,
        requiresPricingConfiguration: false,
        status: CatalogStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
        version: 1,
      });
      repository.listPricing.mockResolvedValueOnce([mockPricingRecord]);

      await expect(
        service.createItem(scope, {
          name: 'Silk Shirt',
          code: 'SILK_SHIRT',
          unitType: UnitType.PIECE,
          serviceIds: [mockServiceRecord.id],
        }),
      ).rejects.toThrow(ConflictException);
    });

    it('allows associating the same item with multiple different services reusing the master record', async () => {
      const secondService: SettingsServiceRecord = {
        ...mockServiceRecord,
        id: '64f0c18f7c4d2f0012ab3499',
        serviceName: 'Wash & Fold',
        code: 'WASH_FOLD',
      };
      repository.findItemByCode.mockResolvedValueOnce(mockItemRecord);
      repository.findService.mockImplementation((_scope, id) =>
        Promise.resolve(id === secondService.id ? secondService : mockServiceRecord),
      );
      repository.findMapping.mockResolvedValue(null); // No existing mapping for second service
      repository.listPricing.mockResolvedValue([]); // No existing pricing for second service

      const result = await service.createItem(scope, {
        name: 'Silk Shirt',
        code: 'SILK_SHIRT',
        unitType: UnitType.PIECE,
        serviceIds: [secondService.id],
        basePrice: 12.0,
      });

      expect(result.id).toBe(mockItemRecord.id);
      expect(repository.createItem).not.toHaveBeenCalled();
      expect(repository.createMapping).toHaveBeenCalledWith(
        scope,
        expect.objectContaining({
          serviceId: secondService.id,
          itemCategoryId: mockItemRecord.id,
          status: CatalogStatus.ACTIVE,
        }),
      );
      expect(repository.createPricing).toHaveBeenCalledWith(
        scope,
        expect.objectContaining({
          serviceId: secondService.id,
          itemCategoryId: mockItemRecord.id,
          basePrice: 12.0,
          status: CatalogStatus.ACTIVE,
        }),
      );
    });

    it('reactivates existing inactive item on createItem with same code', async () => {
      repository.findItemByCode.mockResolvedValueOnce({
        ...mockItemRecord,
        status: CatalogStatus.INACTIVE,
      });
      repository.updateItem.mockResolvedValueOnce({
        ...mockItemRecord,
        status: CatalogStatus.ACTIVE,
      });

      const result = await service.createItem(scope, {
        name: 'Silk Shirt',
        code: 'SILK_SHIRT',
        unitType: UnitType.PIECE,
      });

      expect(repository.updateItem).toHaveBeenCalledWith(
        scope,
        mockItemRecord.id,
        expect.objectContaining({
          status: CatalogStatus.ACTIVE,
        }),
      );
      expect(result.status).toBe(CatalogStatus.ACTIVE);
    });

    it('safely deactivates an item on delete', async () => {
      const result = await service.deleteItem(scope, mockItemRecord.id);

      expect(repository.updateItem).toHaveBeenCalledWith(scope, mockItemRecord.id, {
        status: CatalogStatus.INACTIVE,
      });
      expect(result.status).toBe(CatalogStatus.INACTIVE);
    });
  });

  describe('Categories Management', () => {
    it('creates a custom category and checks uniqueness', async () => {
      const result = await service.createCategory(scope, {
        name: 'Bedding & Linen',
        code: 'BEDDING',
      });

      expect(repository.findCategoryByCode).toHaveBeenCalledWith(scope, 'BEDDING');
      expect(repository.createCategory).toHaveBeenCalled();
      expect(result.id).toBe(mockCategoryRecord.id);
    });

    it('safely deactivates a category on delete', async () => {
      const result = await service.deleteCategory(scope, mockCategoryRecord.id);

      expect(repository.updateCategory).toHaveBeenCalledWith(scope, mockCategoryRecord.id, {
        status: CatalogStatus.INACTIVE,
      });
      expect(result.status).toBe(CatalogStatus.INACTIVE);
    });
  });

  describe('Pricing Management', () => {
    it('updates pricing for service/item configuration', async () => {
      const result = await service.updatePricing(scope, mockPricingRecord.id, {
        basePrice: 20.0,
        taxPct: 5.0,
      });

      expect(repository.updatePricing).toHaveBeenCalledWith(
        scope,
        mockPricingRecord.id,
        expect.objectContaining({ basePrice: 20.0, taxPct: 5.0 }),
      );
      expect(result.basePrice).toBe(20.0);
    });

    it('allows basePrice, taxPct, and effectiveFrom to be mutable in Mongoose schema', () => {
      expect(SettingsServicePricingMongooseSchema.path('basePrice').options.immutable).not.toBe(
        true,
      );
      expect(SettingsServicePricingMongooseSchema.path('taxPct').options.immutable).not.toBe(true);
      expect(SettingsServicePricingMongooseSchema.path('effectiveFrom').options.immutable).not.toBe(
        true,
      );
    });

    it('rejects non-existent pricing ID', async () => {
      repository.findPricing.mockResolvedValueOnce(null);

      await expect(
        service.updatePricing(scope, '64f0c18f7c4d2f0012ab9999', {
          basePrice: 25.0,
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('Permissions & Role-based Access Control', () => {
    it('blocks Staff from mutating services, items, categories, or pricing', async () => {
      const staffScope: SettingsScope = {
        ...scope,
        roleCode: 'Staff',
        permissions: ['orders:read', 'orders:write'],
      };

      await expect(
        service.createService(staffScope, {
          serviceName: 'Test',
          code: 'TEST',
          pricingType: PricingType.PER_ITEM,
        }),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        service.createItem(staffScope, {
          name: 'Test Item',
          code: 'TEST_ITEM',
          unitType: UnitType.PIECE,
        }),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        service.createCategory(staffScope, {
          name: 'Test Category',
          code: 'TEST_CAT',
        }),
      ).rejects.toThrow(ForbiddenException);

      await expect(
        service.updatePricing(staffScope, mockPricingRecord.id, {
          basePrice: 30.0,
        }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('allows Branch Manager with business-settings:write permission to mutate settings', async () => {
      const managerScope: SettingsScope = {
        ...scope,
        roleCode: 'Branch Manager',
        permissions: ['business-settings:write'],
      };

      const result = await service.createService(managerScope, {
        serviceName: 'Laundry Express',
        code: 'LAUNDRY_EXP',
        pricingType: PricingType.PER_KG,
      });

      expect(result).toBeDefined();
    });

    it('blocks Branch Manager without business-settings:write permission from mutating settings', async () => {
      const managerScope: SettingsScope = {
        ...scope,
        roleCode: 'Branch Manager',
        permissions: ['orders:read'],
      };

      await expect(
        service.createService(managerScope, {
          serviceName: 'Laundry Express',
          code: 'LAUNDRY_EXP',
          pricingType: PricingType.PER_KG,
        }),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
