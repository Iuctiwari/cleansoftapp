import { PREDEFINED_CATALOG_TEMPLATES } from '../src/catalog/catalog-template.seed-data';

describe('predefined catalog templates', () => {
  it.each([
    ['dry_cleaning', 'DRY_CLEANING'],
    ['vehicle_wash', 'CAR_WASH'],
    ['salon', 'SALON'],
  ] as const)('defines the %s system template with stable codes', (businessType, code) => {
    const template = PREDEFINED_CATALOG_TEMPLATES.find(
      (candidate) => candidate.businessType === businessType,
    );

    expect(template).toBeDefined();
    expect(template?.code).toBe(code);
    expect(template?.items.length).toBeGreaterThan(0);
    expect(template?.services.length).toBeGreaterThan(0);
    expect(template?.pricing).toHaveLength(template?.mappings.length ?? 0);
    expect(template?.pricing.every((price) => price.basePrice >= 100)).toBe(true);
    expect(template?.mappings.every((mapping) => mapping.requiresPricingConfiguration)).toBe(true);
  });

  it('defines the approved differentiated Dry Cleaning defaults', () => {
    const dryCleaning = PREDEFINED_CATALOG_TEMPLATES.find(
      (template) => template.businessType === 'dry_cleaning',
    )!;
    const dryPrice = (itemCode: string): number | undefined =>
      dryCleaning.pricing.find(
        (price) => price.itemCode === itemCode && price.serviceCode === 'SERVICE_DRY_CLEANING',
      )?.basePrice;

    expect({
      shirt: dryPrice('ITEM_SHIRT'),
      trouser: dryPrice('ITEM_TROUSER'),
      jacket: dryPrice('ITEM_JACKET'),
      suit: dryPrice('ITEM_SUIT'),
      carpet: dryPrice('ITEM_CARPET'),
      shoes: dryPrice('ITEM_SHOES'),
      blanket: dryPrice('ITEM_BLANKET'),
    }).toEqual({
      shirt: 100,
      trouser: 120,
      jacket: 180,
      suit: 300,
      carpet: 500,
      shoes: 200,
      blanket: 250,
    });
  });

  it('uses shared stable codes to deduplicate overlapping templates', () => {
    const dryCleaning = PREDEFINED_CATALOG_TEMPLATES.find(
      (template) => template.businessType === 'dry_cleaning',
    );
    const laundry = PREDEFINED_CATALOG_TEMPLATES.find(
      (template) => template.businessType === 'laundry',
    );

    expect(dryCleaning?.items.some((item) => item.code === 'ITEM_SHIRT')).toBe(true);
    expect(laundry?.items.some((item) => item.code === 'ITEM_SHIRT')).toBe(true);
    expect(dryCleaning?.services.some((service) => service.code === 'SERVICE_WASH_FOLD')).toBe(
      true,
    );
    expect(laundry?.services.some((service) => service.code === 'SERVICE_WASH_FOLD')).toBe(true);
    const sharedPrice = (template: typeof dryCleaning): number | undefined =>
      template?.pricing.find(
        (price) => price.itemCode === 'ITEM_SHIRT' && price.serviceCode === 'SERVICE_WASH_FOLD',
      )?.basePrice;
    expect(sharedPrice(dryCleaning)).toBe(sharedPrice(laundry));
  });

  it('covers every mapping with differentiated prices starting at 100 rupees', () => {
    for (const template of PREDEFINED_CATALOG_TEMPLATES) {
      expect(template.pricing).toHaveLength(template.mappings.length);
      for (const dimension of ['itemCode', 'serviceCode'] as const) {
        const groups = new Map<string, (typeof template.pricing)[number][]>();
        for (const price of template.pricing) {
          const group = groups.get(price[dimension]) ?? [];
          group.push(price);
          groups.set(price[dimension], group);
        }
        for (const prices of groups.values()) {
          expect(new Set(prices.map((price) => price.basePrice)).size).toBe(prices.length);
          expect(prices.every((price) => price.basePrice >= 100)).toBe(true);
        }
      }
    }
  });
});
