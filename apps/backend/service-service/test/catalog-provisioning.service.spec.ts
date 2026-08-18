import { CatalogProvisioningService } from '../src/catalog/catalog-provisioning.service';
import { PREDEFINED_CATALOG_TEMPLATES } from '../src/catalog/catalog-template.seed-data';
import type { CatalogService } from '../src/catalog/catalog.service';
import { CatalogStatus } from '../src/catalog/enums';
import type {
  CatalogRepository,
  CatalogScope,
  CatalogTemplateRecord,
  ItemCategoryRecord,
  ServiceMappingRecord,
  ServiceRecord,
} from '../src/catalog/catalog.types';

const TENANT_A = '64f0c18f7c4d2f0012ab34aa';
const TENANT_B = '64f0c18f7c4d2f0012ab34bb';
const ACTOR = '64f0c18f7c4d2f0012ab34ab';

function entity(
  id: string,
  tenantId: string,
): {
  id: string;
  tenantId: string;
  status: CatalogStatus;
  createdAt: Date;
  updatedAt: Date;
  version: number;
} {
  return {
    id,
    tenantId,
    status: CatalogStatus.ACTIVE,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
    version: 1,
  };
}

function harness(templates: readonly CatalogTemplateRecord[] = PREDEFINED_CATALOG_TEMPLATES): {
  catalog: CatalogService;
  items: Map<string, ItemCategoryRecord>;
  mappings: Map<string, ServiceMappingRecord>;
  priced: Set<string>;
  repository: CatalogRepository;
  services: Map<string, ServiceRecord>;
  subject: CatalogProvisioningService;
} {
  const items = new Map<string, ItemCategoryRecord>();
  const services = new Map<string, ServiceRecord>();
  const mappings = new Map<string, ServiceMappingRecord>();
  const priced = new Set<string>();
  let sequence = 1;
  const key = (scope: CatalogScope, code: string): string => `${scope.tenantId}:${code}`;
  const mappingKey = (scope: CatalogScope, serviceId: string, itemId: string): string =>
    `${scope.tenantId}:${serviceId}:${itemId}`;

  const repository = {
    listTemplatesByBusinessTypes: jest.fn((types: readonly string[]) =>
      Promise.resolve(templates.filter((template) => types.includes(template.businessType))),
    ),
    findItemCategoryByCode: jest.fn((scope: CatalogScope, code: string) =>
      Promise.resolve(items.get(key(scope, code)) ?? null),
    ),
    findServiceByCode: jest.fn((scope: CatalogScope, code: string) =>
      Promise.resolve(services.get(key(scope, code)) ?? null),
    ),
    findTenantWideMapping: jest.fn((scope: CatalogScope, serviceId: string, itemId: string) =>
      Promise.resolve(mappings.get(mappingKey(scope, serviceId, itemId)) ?? null),
    ),
    hasAnyTenantWidePricing: jest.fn((scope: CatalogScope, serviceId: string, itemId: string) =>
      Promise.resolve(priced.has(mappingKey(scope, serviceId, itemId))),
    ),
    updateMapping: jest.fn(
      (scope: CatalogScope, id: string, input: { requiresPricingConfiguration?: boolean }) => {
        const entry = [...mappings.entries()].find(([, mapping]) => mapping.id === id);
        if (!entry) return Promise.resolve(null);
        const updated = { ...entry[1], ...input };
        mappings.set(entry[0], updated);
        return Promise.resolve(updated);
      },
    ),
    updateItemCategory: jest.fn(
      (scope: CatalogScope, id: string, input: { catalogGroupCodes?: readonly string[] }) => {
        const entry = [...items.entries()].find(([, item]) => item.id === id);
        if (!entry) return Promise.resolve(null);
        const updated = { ...entry[1], ...input };
        items.set(entry[0], updated);
        return Promise.resolve(updated);
      },
    ),
  } as unknown as CatalogRepository;

  const catalog = {
    createItemCategory: jest.fn((scope: CatalogScope, input: ItemCategoryRecord) => {
      const record = {
        ...entity(`item-${sequence++}`, scope.tenantId),
        name: input.name,
        code: input.code,
        unitType: input.unitType,
        branchIds: input.branchIds,
        catalogGroupCodes: [],
      } as ItemCategoryRecord;
      items.set(key(scope, record.code), record);
      return Promise.resolve(record);
    }),
    createService: jest.fn((scope: CatalogScope, input: ServiceRecord) => {
      const record = {
        ...entity(`service-${sequence++}`, scope.tenantId),
        name: input.name,
        serviceName: input.name,
        code: input.code,
        pricingType: input.pricingType,
        branchIds: input.branchIds,
      } as ServiceRecord;
      services.set(key(scope, record.code), record);
      return Promise.resolve(record);
    }),
    createMapping: jest.fn(
      (
        scope: CatalogScope,
        input: {
          itemCategoryId: string;
          serviceId: string;
          requiresPricingConfiguration: boolean;
        },
      ) => {
        const service = [...services.values()].find((value) => value.id === input.serviceId)!;
        const record = {
          ...entity(`mapping-${sequence++}`, scope.tenantId),
          ...input,
          branchId: null,
          pricingType: service.pricingType,
        } as ServiceMappingRecord;
        mappings.set(mappingKey(scope, input.serviceId, input.itemCategoryId), record);
        return Promise.resolve(record);
      },
    ),
    createPricing: jest.fn(
      (scope: CatalogScope, serviceId: string, input: { itemCategoryId: string }) => {
        priced.add(mappingKey(scope, serviceId, input.itemCategoryId));
        return Promise.resolve({});
      },
    ),
  } as unknown as CatalogService;

  return {
    catalog,
    items,
    mappings,
    priced,
    repository,
    services,
    subject: new CatalogProvisioningService(catalog, repository),
  };
}

describe('CatalogProvisioningService', () => {
  it('fails safely when a requested system template has not been installed', async () => {
    const test = harness([]);

    await expect(
      test.subject.provision({
        tenantId: TENANT_A,
        actorId: ACTOR,
        businessTypes: ['dry_cleaning'],
      }),
    ).rejects.toThrow('Catalog templates are not installed for: dry_cleaning');
    expect(test.items.size).toBe(0);
  });

  it('creates a tenant-wide catalog and is idempotent', async () => {
    const test = harness();
    const input = { tenantId: TENANT_A, actorId: ACTOR, businessTypes: ['dry_cleaning'] as const };

    const first = await test.subject.provision(input);
    const second = await test.subject.provision(input);

    expect(first.createdItems).toBeGreaterThan(0);
    expect(first.createdServices).toBeGreaterThan(0);
    expect(first.createdMappings).toBeGreaterThan(0);
    expect(second.createdItems + second.createdServices + second.createdMappings).toBe(0);
    expect(test.items.size).toBe(first.createdItems);
    expect(test.services.size).toBe(first.createdServices);
    expect(test.mappings.size).toBe(first.createdMappings);
    expect([...test.items.values()].every((item) => item.branchIds.length === 0)).toBe(true);
    expect([...test.services.values()].every((service) => service.branchIds.length === 0)).toBe(
      true,
    );
    expect([...test.mappings.values()].every((mapping) => mapping.branchId === null)).toBe(true);
  });

  it('merges multiple business types by stable code without duplicate shared records', async () => {
    const test = harness();
    await test.subject.provision({
      tenantId: TENANT_A,
      actorId: ACTOR,
      businessTypes: ['dry_cleaning', 'laundry'],
    });

    expect([...test.items.values()].filter((item) => item.code === 'ITEM_SHIRT')).toHaveLength(1);
    expect(test.items.get(`${TENANT_A}:ITEM_SHIRT`)?.catalogGroupCodes).toEqual([
      'DRY_CLEANING',
      'LAUNDRY',
    ]);
    expect(
      [...test.services.values()].filter((service) => service.code === 'SERVICE_WASH_FOLD'),
    ).toHaveLength(1);
  });

  it('keeps tenant catalogs isolated even when their template codes match', async () => {
    const test = harness();
    await test.subject.provision({ tenantId: TENANT_A, actorId: ACTOR, businessTypes: ['salon'] });
    await test.subject.provision({ tenantId: TENANT_B, actorId: ACTOR, businessTypes: ['salon'] });

    const salonItems = [...test.items.values()].filter((item) => item.code === 'SALON_HAIR');
    expect(salonItems.map((item) => item.tenantId).sort()).toEqual([TENANT_A, TENANT_B].sort());
  });

  it('reuses custom records with the same stable code without overwriting them', async () => {
    const test = harness();
    const custom = {
      ...entity('custom-shirt', TENANT_A),
      name: 'My Custom Shirt Name',
      code: 'ITEM_SHIRT',
      unitType: PREDEFINED_CATALOG_TEMPLATES[0].items[0].unitType,
      branchIds: [],
      catalogGroupCodes: [],
    } as ItemCategoryRecord;
    test.items.set(`${TENANT_A}:ITEM_SHIRT`, custom);

    await test.subject.provision({
      tenantId: TENANT_A,
      actorId: ACTOR,
      businessTypes: ['dry_cleaning'],
    });

    expect(test.items.get(`${TENANT_A}:ITEM_SHIRT`)?.name).toBe('My Custom Shirt Name');
    expect(test.items.get(`${TENANT_A}:ITEM_SHIRT`)?.catalogGroupCodes).toEqual(['DRY_CLEANING']);
  });

  it('creates approved defaults once and preserves existing tenant pricing', async () => {
    const dry = PREDEFINED_CATALOG_TEMPLATES.find(
      (template) => template.businessType === 'dry_cleaning',
    )!;
    const test = harness([dry]);
    await test.subject.provision({
      tenantId: TENANT_A,
      actorId: ACTOR,
      businessTypes: ['dry_cleaning'],
    });
    const item = [...test.items.values()].find((value) => value.code === 'ITEM_SHIRT')!;
    const service = [...test.services.values()].find(
      (value) => value.code === 'SERVICE_DRY_CLEANING',
    )!;
    test.priced.add(`${TENANT_A}:${service.id}:${item.id}`);

    const second = await test.subject.provision({
      tenantId: TENANT_A,
      actorId: ACTOR,
      businessTypes: ['dry_cleaning'],
    });

    expect(second.preservedPrices).toBe(dry.pricing.length);
    expect((test.catalog.createPricing as jest.Mock).mock.calls).toHaveLength(dry.pricing.length);
    expect(second.pricingConfigurationRequired).toBe(0);
    expect(
      PREDEFINED_CATALOG_TEMPLATES.flatMap((template) => template.pricing).every(
        (price) => price.basePrice >= 100,
      ),
    ).toBe(true);
  });

  it('never overwrites customized tenant pricing', async () => {
    const dry = PREDEFINED_CATALOG_TEMPLATES.find(
      (template) => template.businessType === 'dry_cleaning',
    )!;
    const test = harness([dry]);
    (test.repository.hasAnyTenantWidePricing as jest.Mock).mockResolvedValue(true);

    const result = await test.subject.provision({
      tenantId: TENANT_A,
      actorId: ACTOR,
      businessTypes: ['dry_cleaning'],
    });

    expect(result.createdPrices).toBe(0);
    expect(result.preservedPrices).toBe(dry.pricing.length);
    expect((test.catalog.createPricing as jest.Mock).mock.calls).toHaveLength(0);
  });
});
