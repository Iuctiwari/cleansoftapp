import {
  ItemCategoryMongooseSchema,
  ServiceCategoryMongooseSchema,
  ServiceMappingMongooseSchema,
  ServiceMongooseSchema,
  ServicePricingMongooseSchema,
} from '../src/catalog/catalog.schema';

describe('Catalog MongoDB schemas', () => {
  it('registers tenant-scoped code and mapping uniqueness indexes', () => {
    expect(ServiceCategoryMongooseSchema.indexes()).toContainEqual(
      expect.arrayContaining([{ tenantId: 1, code: 1 }, expect.objectContaining({ unique: true })]),
    );
    expect(ItemCategoryMongooseSchema.indexes()).toContainEqual(
      expect.arrayContaining([{ tenantId: 1, code: 1 }, expect.objectContaining({ unique: true })]),
    );
    expect(ServiceMongooseSchema.indexes()).toContainEqual(
      expect.arrayContaining([{ tenantId: 1, code: 1 }, expect.objectContaining({ unique: true })]),
    );
    expect(ServiceMappingMongooseSchema.indexes()).toContainEqual(
      expect.arrayContaining([
        { tenantId: 1, itemCategoryId: 1, serviceId: 1, branchId: 1 },
        expect.objectContaining({ unique: true }),
      ]),
    );
  });

  it('registers effective-price lookup and immutable version indexes', () => {
    const indexes = ServicePricingMongooseSchema.indexes();
    expect(indexes.some(([, options]) => options.name === 'service_pricing_effective_lookup')).toBe(
      true,
    );
    expect(
      indexes.some(
        ([, options]) =>
          options.name === 'service_pricing_version_unique' && options.unique === true,
      ),
    ).toBe(true);
  });

  it('keeps price values immutable while allowing only the effective window to be closed', () => {
    expect(ServicePricingMongooseSchema.path('basePrice').options.immutable).toBe(true);
    expect(ServicePricingMongooseSchema.path('taxPct').options.immutable).toBe(true);
    expect(ServicePricingMongooseSchema.path('effectiveFrom').options.immutable).toBe(true);
    expect(ServicePricingMongooseSchema.path('effectiveTo').options.immutable).not.toBe(true);
  });
});
