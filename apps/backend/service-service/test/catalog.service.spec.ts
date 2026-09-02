import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';

import { CatalogService } from '../src/catalog/catalog.service';
import { CatalogStatus, PricingType, UnitType } from '../src/catalog/enums';
import type {
  CatalogDependencies,
  CatalogRepository,
  CatalogScope,
  ItemCategoryRecord,
  ServiceMappingRecord,
  ServicePricingRecord,
  ServiceRecord,
} from '../src/catalog/catalog.types';

const ID = '64f0c18f7c4d2f0012ab34cd';
const ITEM_ID = '64f0c18f7c4d2f0012ab34ce';
const PRICING_ID = '64f0c18f7c4d2f0012ab34d0';
const TENANT_ID = '64f0c18f7c4d2f0012ab34aa';
const ACTOR_ID = '64f0c18f7c4d2f0012ab34ab';
const BRANCH_ID = 'branch-a';

function scope(roleCode = 'tenant_owner'): CatalogScope {
  return {
    actorId: ACTOR_ID,
    authorization: 'Bearer token',
    branchId: BRANCH_ID,
    permissions: [],
    roleCode,
    tenantId: TENANT_ID,
  };
}

function base(): {
  id: string;
  tenantId: string;
  status: CatalogStatus;
  createdAt: Date;
  updatedAt: Date;
  version: number;
} {
  return {
    id: ID,
    tenantId: TENANT_ID,
    status: CatalogStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
    version: 2,
  };
}

function serviceRecord(
  type: PricingType = PricingType.PER_ITEM,
  overrides: Partial<ServiceRecord> = {},
): ServiceRecord {
  return {
    ...base(),
    serviceName: 'Cleaning',
    name: 'Cleaning',
    code: 'CLEAN',
    pricingType: type,
    branchIds: [],
    ...overrides,
  };
}

function itemRecord(overrides: Partial<ItemCategoryRecord> = {}): ItemCategoryRecord {
  return {
    ...base(),
    id: ITEM_ID,
    name: 'Garment',
    code: 'GARMENT',
    unitType: UnitType.PIECE,
    branchIds: [],
    catalogGroupCodes: [],
    ...overrides,
  };
}

function mapping(type: PricingType = PricingType.PER_ITEM): ServiceMappingRecord {
  return {
    ...base(),
    id: '64f0c18f7c4d2f0012ab34cf',
    itemCategoryId: ITEM_ID,
    serviceId: ID,
    branchId: null,
    pricingType: type,
    requiresPricingConfiguration: false,
  };
}

function price(type: PricingType = PricingType.PER_ITEM): ServicePricingRecord {
  return {
    ...base(),
    id: PRICING_ID,
    itemCategoryId: ITEM_ID,
    serviceId: ID,
    branchId: null,
    pricingType: type,
    basePrice: 80,
    taxPct: 5,
    effectiveFrom: new Date('2026-01-01T00:00:00.000Z'),
  };
}

describe('CatalogService', () => {
  let repository: jest.Mocked<CatalogRepository>;
  let dependencies: jest.Mocked<CatalogDependencies>;
  let catalog: CatalogService;

  beforeEach(() => {
    repository = {
      listTemplatesByBusinessTypes: jest.fn(),
      upsertTemplate: jest.fn(),
      findItemCategoryByCode: jest.fn(),
      findServiceByCode: jest.fn(),
      findTenantWideMapping: jest.fn(),
      hasAnyTenantWidePricing: jest.fn(),
      createItemCategory: jest.fn(),
      findItemCategory: jest.fn().mockResolvedValue(itemRecord()),
      listItemCategories: jest.fn(),
      updateItemCategory: jest.fn(),
      createService: jest.fn(),
      findService: jest.fn().mockResolvedValue(serviceRecord()),
      listServices: jest.fn(),
      updateService: jest.fn(),
      createServiceCategory: jest.fn(),
      findServiceCategory: jest.fn(),
      listServiceCategories: jest.fn(),
      updateServiceCategory: jest.fn(),
      createMapping: jest.fn().mockResolvedValue(mapping()),
      findMapping: jest.fn(),
      findEffectiveMapping: jest.fn().mockResolvedValue(mapping()),
      listMappings: jest.fn().mockResolvedValue([]),
      updateMapping: jest.fn(),
      createPricingIfNoOverlap: jest.fn().mockResolvedValue(price()),
      findPricing: jest.fn().mockResolvedValue(price()),
      updatePricingLifecycle: jest.fn().mockResolvedValue(price()),
      listPricing: jest.fn(),
      resolvePricing: jest.fn().mockResolvedValue(price()),
    };
    dependencies = { assertBranches: jest.fn().mockResolvedValue(undefined) };
    catalog = new CatalogService(repository, dependencies);
  });

  it.each([
    [PricingType.PER_ITEM, { quantity: 3 }, 240],
    [PricingType.PER_KG, { weight: 2.5 }, 200],
    [PricingType.PER_PAIR, { quantity: 2 }, 160],
    [PricingType.PER_HOUR, { quantity: 1.5 }, 120],
    [PricingType.FIXED, {}, 80],
    [PricingType.CUSTOM, { quantity: 4 }, 320],
  ])('quotes %s pricing on the backend', async (type, units, expected) => {
    repository.findService.mockResolvedValue(serviceRecord(type));
    repository.findEffectiveMapping.mockResolvedValue(mapping(type));
    repository.resolvePricing.mockResolvedValue(price(type));
    const quote = await catalog.quote(scope(), ID, { itemCategoryId: ITEM_ID, ...units });
    expect(quote.lineAmount).toBe(expected);
    expect(quote.basePrice).toBe(80);
    expect(quote.servicePricingId).toBe('64f0c18f7c4d2f0012ab34d0');
  });

  it('allows Order Service to resolve an immutable quote without client units', async () => {
    const quote = await catalog.quote(scope(), ID, { itemCategoryId: ITEM_ID });
    expect(quote.lineAmount).toBeUndefined();
    expect(quote.version).toBe(2);
    expect(quote.effectiveFrom.toISOString()).toBe('2026-01-01T00:00:00.000Z');
  });

  it('allows the authenticated Branch Manager role label to read catalog data', async () => {
    await expect(catalog.getService(scope('Branch Manager'), ID)).resolves.toMatchObject({
      id: ID,
    });
  });

  it('rejects invalid quantity/weight combinations', async () => {
    repository.findService.mockResolvedValue(serviceRecord(PricingType.PER_KG));
    repository.resolvePricing.mockResolvedValue(price(PricingType.PER_KG));
    await expect(
      catalog.quote(scope(), ID, { itemCategoryId: ITEM_ID, quantity: 2 }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects inactive and branch-unavailable catalog references', async () => {
    repository.findService.mockResolvedValueOnce(
      serviceRecord(PricingType.PER_ITEM, { status: CatalogStatus.INACTIVE }),
    );
    await expect(catalog.quote(scope(), ID, { itemCategoryId: ITEM_ID })).rejects.toBeInstanceOf(
      BadRequestException,
    );
    repository.findService.mockResolvedValueOnce(
      serviceRecord(PricingType.PER_ITEM, { branchIds: ['branch-b'] }),
    );
    await expect(catalog.quote(scope(), ID, { itemCategoryId: ITEM_ID })).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('rejects a missing category/service mapping', async () => {
    repository.findEffectiveMapping.mockResolvedValue(null);
    await expect(catalog.quote(scope(), ID, { itemCategoryId: ITEM_ID })).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('blocks Staff and Cashier mutations while allowing reads/quotes', async () => {
    await expect(
      catalog.createService(scope('staff'), {
        name: 'Cleaning',
        code: 'C',
        pricingType: PricingType.PER_ITEM,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    await expect(
      catalog.createItemCategory(scope('cashier'), {
        name: 'Garment',
        code: 'G',
        unitType: UnitType.PIECE,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
    await expect(
      catalog.quote(scope('staff'), ID, { itemCategoryId: ITEM_ID }),
    ).resolves.toBeDefined();
  });

  it('rejects overlapping effective pricing windows', async () => {
    repository.createPricingIfNoOverlap.mockResolvedValue(null);
    await expect(
      catalog.createPricing(scope(), ID, {
        itemCategoryId: ITEM_ID,
        basePrice: 100,
        effectiveFrom: '2026-01-01T00:00:00.000Z',
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('allows only one of two concurrent overlapping pricing requests', async () => {
    repository.createPricingIfNoOverlap.mockResolvedValueOnce(price()).mockResolvedValueOnce(null);
    const input = {
      itemCategoryId: ITEM_ID,
      basePrice: 100,
      effectiveFrom: '2026-01-01T00:00:00.000Z',
    };

    const results = await Promise.allSettled([
      catalog.createPricing(scope(), ID, input),
      catalog.createPricing(scope(), ID, input),
    ]);

    expect(results.filter((result) => result.status === 'fulfilled')).toHaveLength(1);
    expect(results.filter((result) => result.status === 'rejected')).toHaveLength(1);
  });

  it('closes or deactivates a pricing version without replacing its price snapshot', async () => {
    const closed = {
      ...price(),
      effectiveTo: new Date('2026-07-01T00:00:00.000Z'),
    };
    repository.updatePricingLifecycle.mockResolvedValue(closed);

    await expect(
      catalog.updatePricing(scope(), ID, PRICING_ID, {
        effectiveTo: '2026-07-01T00:00:00.000Z',
      }),
    ).resolves.toEqual(closed);
    expect(repository.updatePricingLifecycle.mock.calls).toContainEqual([
      scope(),
      ID,
      PRICING_ID,
      { effectiveTo: new Date('2026-07-01T00:00:00.000Z') },
    ]);
    expect(closed.basePrice).toBe(80);
  });

  it('does not quote an inactive or no-longer-effective pricing version', async () => {
    repository.resolvePricing.mockResolvedValue(null);

    await expect(catalog.quote(scope(), ID, { itemCategoryId: ITEM_ID })).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('always scopes mapping list and relationship enrichment to the authenticated branch', async () => {
    await catalog.listMappings(scope(), {});
    await catalog.getService(scope(), ID);
    await catalog.getItemCategory(scope(), ITEM_ID);

    expect(repository.listMappings.mock.calls).toEqual(
      expect.arrayContaining([
        [scope(), expect.objectContaining({ branchId: BRANCH_ID })],
        [scope(), expect.objectContaining({ serviceId: ID, branchId: BRANCH_ID })],
        [scope(), expect.objectContaining({ itemCategoryId: ITEM_ID, branchId: BRANCH_ID })],
      ]),
    );
  });

  it('validates branch ownership before persisting scoped catalog data', async () => {
    repository.createItemCategory.mockResolvedValue(itemRecord());
    await catalog.createItemCategory(scope(), {
      name: 'Garment',
      code: ' garment ',
      unitType: UnitType.PIECE,
      branchIds: [BRANCH_ID],
    });
    expect(dependencies.assertBranches.mock.calls).toContainEqual([scope(), [BRANCH_ID]]);
    expect(repository.createItemCategory.mock.calls).toContainEqual([
      scope(),
      expect.objectContaining({ code: 'GARMENT' }),
    ]);
  });

  it('maps duplicate database constraints to a conflict', async () => {
    repository.createService.mockRejectedValue({ code: 11000 });
    await expect(
      catalog.createService(scope(), {
        name: 'Cleaning',
        code: 'CLEAN',
        pricingType: PricingType.PER_ITEM,
      }),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
