import { CatalogStatus, PricingType, UnitType } from './enums';

export interface TemplateItem {
  readonly code: string;
  readonly name: string;
  readonly unitType: UnitType;
  readonly description?: string;
}

export interface TemplateService {
  readonly code: string;
  readonly name: string;
  readonly pricingType: PricingType;
  readonly description?: string;
}

export interface TemplateMapping {
  readonly itemCode: string;
  readonly serviceCode: string;
  readonly requiresPricingConfiguration: boolean;
}

export interface TemplatePricing {
  readonly itemCode: string;
  readonly serviceCode: string;
  readonly basePrice: number;
  readonly taxPct: number;
  readonly effectiveFrom: Date;
}

export interface TemplateRecord {
  readonly code: string;
  readonly businessType: string;
  readonly name: string;
  readonly status: CatalogStatus;
  readonly templateVersion: number;
  readonly items: readonly TemplateItem[];
  readonly services: readonly TemplateService[];
  readonly mappings: readonly TemplateMapping[];
  readonly pricing: readonly TemplatePricing[];
}

const DEFAULT_EFFECTIVE_FROM = new Date('2026-01-01T00:00:00.000Z');

function mappings(
  itemCodes: readonly string[],
  serviceCodes: readonly string[],
): readonly TemplateMapping[] {
  return itemCodes.flatMap((itemCode) =>
    serviceCodes.map((serviceCode) => ({
      itemCode,
      serviceCode,
      requiresPricingConfiguration: false,
    })),
  );
}

function pricing(
  definitions: readonly TemplateMapping[],
  itemPrices: Readonly<Record<string, number>>,
  serviceAdjustments: Readonly<Record<string, number>>,
): readonly TemplatePricing[] {
  return definitions.map(({ itemCode, serviceCode }) => {
    const itemPrice = itemPrices[itemCode];
    const serviceAdjustment = serviceAdjustments[serviceCode];
    if (itemPrice === undefined || serviceAdjustment === undefined) {
      throw new Error(`Missing predefined price for ${itemCode} + ${serviceCode}`);
    }
    return {
      itemCode,
      serviceCode,
      basePrice: itemPrice + serviceAdjustment,
      taxPct: 0,
      effectiveFrom: DEFAULT_EFFECTIVE_FROM,
    };
  });
}

function template(input: {
  code: string;
  businessType: string;
  name: string;
  items: readonly TemplateItem[];
  services: readonly TemplateService[];
  mappings?: readonly TemplateMapping[];
  itemPrices?: Readonly<Record<string, number>>;
  serviceAdjustments?: Readonly<Record<string, number>>;
}): TemplateRecord {
  const resolvedMappings =
    input.mappings ??
    mappings(
      input.items.map((item) => item.code),
      input.services.map((service) => service.code),
    );
  return {
    code: input.code,
    businessType: input.businessType.toLowerCase(),
    name: input.name,
    items: input.items,
    services: input.services,
    status: CatalogStatus.ACTIVE,
    templateVersion: 2,
    mappings: resolvedMappings,
    pricing:
      resolvedMappings.length === 0
        ? []
        : pricing(resolvedMappings, input.itemPrices ?? {}, input.serviceAdjustments ?? {}),
  };
}

const garmentItems: readonly TemplateItem[] = [
  { code: 'ITEM_SHIRT', name: 'Shirt', unitType: UnitType.PIECE },
  { code: 'ITEM_TROUSER', name: 'Trouser', unitType: UnitType.PIECE },
  { code: 'ITEM_SUIT', name: 'Suit', unitType: UnitType.PIECE },
  { code: 'ITEM_JACKET', name: 'Jacket', unitType: UnitType.PIECE },
  { code: 'ITEM_CARPET', name: 'Carpet', unitType: UnitType.PIECE },
  { code: 'ITEM_SHOES', name: 'Shoes', unitType: UnitType.PAIR },
  { code: 'ITEM_BLANKET', name: 'Blanket', unitType: UnitType.PIECE },
];

export const PREDEFINED_CATALOG_TEMPLATES: readonly TemplateRecord[] = [
  template({
    code: 'DRY_CLEANING',
    businessType: 'dry_cleaning',
    name: 'Dry Cleaning Template',
    items: garmentItems,
    services: [
      { code: 'SERVICE_DRY_CLEANING', name: 'Dry Cleaning', pricingType: PricingType.PER_ITEM },
      { code: 'SERVICE_WASH_FOLD', name: 'Wash & Fold', pricingType: PricingType.PER_ITEM },
      { code: 'SERVICE_IRONING', name: 'Ironing', pricingType: PricingType.PER_ITEM },
      {
        code: 'SERVICE_PREMIUM_CLEANING',
        name: 'Premium Cleaning',
        pricingType: PricingType.PER_ITEM,
      },
    ],
    itemPrices: {
      ITEM_SHIRT: 100,
      ITEM_TROUSER: 120,
      ITEM_SUIT: 300,
      ITEM_JACKET: 180,
      ITEM_CARPET: 500,
      ITEM_SHOES: 200,
      ITEM_BLANKET: 250,
    },
    serviceAdjustments: {
      SERVICE_DRY_CLEANING: 0,
      SERVICE_WASH_FOLD: 30,
      SERVICE_IRONING: 10,
      SERVICE_PREMIUM_CLEANING: 80,
    },
  }),
  template({
    code: 'LAUNDRY',
    businessType: 'laundry',
    name: 'Laundry Template',
    items: [
      ...garmentItems.filter((item) =>
        ['ITEM_SHIRT', 'ITEM_TROUSER', 'ITEM_BLANKET'].includes(item.code),
      ),
      { code: 'ITEM_BEDSHEET', name: 'Bedsheet', unitType: UnitType.PIECE },
      { code: 'ITEM_CURTAIN', name: 'Curtain', unitType: UnitType.PIECE },
    ],
    services: [
      { code: 'SERVICE_WASH_FOLD', name: 'Wash & Fold', pricingType: PricingType.PER_ITEM },
      { code: 'SERVICE_IRONING', name: 'Ironing', pricingType: PricingType.PER_ITEM },
      { code: 'SERVICE_WASH_ONLY', name: 'Wash Only', pricingType: PricingType.PER_ITEM },
    ],
    itemPrices: {
      ITEM_SHIRT: 100,
      ITEM_TROUSER: 120,
      ITEM_BLANKET: 250,
      ITEM_BEDSHEET: 180,
      ITEM_CURTAIN: 220,
    },
    serviceAdjustments: {
      SERVICE_WASH_FOLD: 30,
      SERVICE_IRONING: 10,
      SERVICE_WASH_ONLY: 20,
    },
  }),
  template({
    code: 'CAR_WASH',
    businessType: 'vehicle_wash',
    name: 'Car Wash Template',
    items: [
      { code: 'VEHICLE_HATCHBACK', name: 'Hatchback', unitType: UnitType.PIECE },
      { code: 'VEHICLE_SEDAN', name: 'Sedan', unitType: UnitType.PIECE },
      { code: 'VEHICLE_SUV', name: 'SUV', unitType: UnitType.PIECE },
      { code: 'VEHICLE_BIKE', name: 'Bike', unitType: UnitType.PIECE },
    ],
    services: [
      { code: 'CAR_INTERIOR', name: 'Interior Cleaning', pricingType: PricingType.PER_ITEM },
      { code: 'CAR_EXTERIOR', name: 'Exterior Cleaning', pricingType: PricingType.PER_ITEM },
      { code: 'CAR_FULL_WASH', name: 'Full Wash', pricingType: PricingType.PER_ITEM },
    ],
    itemPrices: {
      VEHICLE_HATCHBACK: 100,
      VEHICLE_SEDAN: 150,
      VEHICLE_SUV: 220,
      VEHICLE_BIKE: 120,
    },
    serviceAdjustments: {
      CAR_INTERIOR: 100,
      CAR_EXTERIOR: 0,
      CAR_FULL_WASH: 150,
    },
  }),
  template({
    code: 'SALON',
    businessType: 'salon',
    name: 'Salon Template',
    items: [
      { code: 'SALON_HAIR', name: 'Hair', unitType: UnitType.PIECE },
      { code: 'SALON_FACE', name: 'Face', unitType: UnitType.PIECE },
      { code: 'SALON_HANDS', name: 'Hands', unitType: UnitType.PAIR },
      { code: 'SALON_FEET', name: 'Feet', unitType: UnitType.PAIR },
      { code: 'SALON_NAILS', name: 'Nails', unitType: UnitType.PIECE },
    ],
    services: [
      { code: 'SALON_HAIRCUT', name: 'Haircut', pricingType: PricingType.PER_ITEM },
      { code: 'SALON_HAIR_WASH', name: 'Hair Wash', pricingType: PricingType.PER_ITEM },
      { code: 'SALON_HAIR_COLOR', name: 'Hair Coloring', pricingType: PricingType.PER_ITEM },
      { code: 'SALON_HAIR_STYLING', name: 'Hair Styling', pricingType: PricingType.PER_ITEM },
      { code: 'SALON_FACIAL', name: 'Facial', pricingType: PricingType.PER_ITEM },
      { code: 'SALON_MANICURE', name: 'Manicure', pricingType: PricingType.PER_ITEM },
      { code: 'SALON_PEDICURE', name: 'Pedicure', pricingType: PricingType.PER_ITEM },
      { code: 'SALON_CURLING', name: 'Curling', pricingType: PricingType.PER_ITEM },
      { code: 'SALON_STRAIGHTENING', name: 'Straightening', pricingType: PricingType.PER_ITEM },
    ],
    mappings: [
      ...mappings(
        ['SALON_HAIR'],
        [
          'SALON_HAIRCUT',
          'SALON_HAIR_WASH',
          'SALON_HAIR_COLOR',
          'SALON_HAIR_STYLING',
          'SALON_CURLING',
          'SALON_STRAIGHTENING',
        ],
      ),
      ...mappings(['SALON_FACE'], ['SALON_FACIAL']),
      ...mappings(['SALON_HANDS', 'SALON_NAILS'], ['SALON_MANICURE']),
      ...mappings(['SALON_FEET', 'SALON_NAILS'], ['SALON_PEDICURE']),
    ],
    itemPrices: {
      SALON_HAIR: 100,
      SALON_FACE: 200,
      SALON_HANDS: 150,
      SALON_FEET: 180,
      SALON_NAILS: 100,
    },
    serviceAdjustments: {
      SALON_HAIRCUT: 0,
      SALON_HAIR_WASH: 50,
      SALON_HAIR_COLOR: 300,
      SALON_HAIR_STYLING: 100,
      SALON_FACIAL: 0,
      SALON_MANICURE: 0,
      SALON_PEDICURE: 20,
      SALON_CURLING: 180,
      SALON_STRAIGHTENING: 350,
    },
  }),
  template({
    code: 'TAILORING',
    businessType: 'tailoring',
    name: 'Tailoring Template',
    items: [
      ...garmentItems.filter((item) =>
        ['ITEM_SHIRT', 'ITEM_TROUSER', 'ITEM_SUIT', 'ITEM_JACKET'].includes(item.code),
      ),
      { code: 'ITEM_DRESS', name: 'Dress', unitType: UnitType.PIECE },
    ],
    services: [
      { code: 'TAILOR_STITCHING', name: 'Stitching', pricingType: PricingType.PER_ITEM },
      { code: 'TAILOR_ALTERATION', name: 'Alteration', pricingType: PricingType.PER_ITEM },
      { code: 'TAILOR_REPAIR', name: 'Repair', pricingType: PricingType.PER_ITEM },
    ],
    itemPrices: {
      ITEM_SHIRT: 150,
      ITEM_TROUSER: 180,
      ITEM_SUIT: 400,
      ITEM_JACKET: 300,
      ITEM_DRESS: 350,
    },
    serviceAdjustments: {
      TAILOR_STITCHING: 100,
      TAILOR_ALTERATION: 20,
      TAILOR_REPAIR: 0,
    },
  }),
  template({
    code: 'SHOE_CLEANING',
    businessType: 'shoe_cleaning',
    name: 'Shoe Cleaning Template',
    items: [
      { code: 'ITEM_SHOES', name: 'Shoes', unitType: UnitType.PAIR },
      { code: 'ITEM_SNEAKERS', name: 'Sneakers', unitType: UnitType.PAIR },
      { code: 'ITEM_LEATHER_SHOES', name: 'Leather Shoes', unitType: UnitType.PAIR },
    ],
    services: [
      { code: 'SHOE_BASIC_CLEAN', name: 'Basic Cleaning', pricingType: PricingType.PER_PAIR },
      { code: 'SHOE_DEEP_CLEAN', name: 'Deep Cleaning', pricingType: PricingType.PER_PAIR },
      { code: 'SHOE_POLISH', name: 'Polishing', pricingType: PricingType.PER_PAIR },
    ],
    itemPrices: {
      ITEM_SHOES: 100,
      ITEM_SNEAKERS: 120,
      ITEM_LEATHER_SHOES: 150,
    },
    serviceAdjustments: {
      SHOE_BASIC_CLEAN: 0,
      SHOE_DEEP_CLEAN: 100,
      SHOE_POLISH: 50,
    },
  }),
  template({
    code: 'APPLIANCE_REPAIR',
    businessType: 'appliance_repair',
    name: 'Appliance Repair Template',
    items: [
      { code: 'APPLIANCE_WASHING_MACHINE', name: 'Washing Machine', unitType: UnitType.PIECE },
      { code: 'APPLIANCE_REFRIGERATOR', name: 'Refrigerator', unitType: UnitType.PIECE },
      { code: 'APPLIANCE_AIR_CONDITIONER', name: 'Air Conditioner', unitType: UnitType.PIECE },
    ],
    services: [
      { code: 'APPLIANCE_INSPECTION', name: 'Inspection', pricingType: PricingType.FIXED },
      { code: 'APPLIANCE_REPAIR_SERVICE', name: 'Repair', pricingType: PricingType.CUSTOM },
    ],
    itemPrices: {
      APPLIANCE_WASHING_MACHINE: 100,
      APPLIANCE_REFRIGERATOR: 150,
      APPLIANCE_AIR_CONDITIONER: 200,
    },
    serviceAdjustments: {
      APPLIANCE_INSPECTION: 0,
      APPLIANCE_REPAIR_SERVICE: 300,
    },
  }),
  template({
    code: 'MOBILE_REPAIR',
    businessType: 'mobile_repair',
    name: 'Mobile Repair Template',
    items: [
      { code: 'DEVICE_SMARTPHONE', name: 'Smartphone', unitType: UnitType.PIECE },
      { code: 'DEVICE_TABLET', name: 'Tablet', unitType: UnitType.PIECE },
    ],
    services: [
      { code: 'MOBILE_DIAGNOSTIC', name: 'Diagnostic', pricingType: PricingType.FIXED },
      { code: 'MOBILE_SCREEN_REPAIR', name: 'Screen Repair', pricingType: PricingType.PER_ITEM },
      {
        code: 'MOBILE_BATTERY_REPLACEMENT',
        name: 'Battery Replacement',
        pricingType: PricingType.PER_ITEM,
      },
    ],
    itemPrices: {
      DEVICE_SMARTPHONE: 100,
      DEVICE_TABLET: 150,
    },
    serviceAdjustments: {
      MOBILE_DIAGNOSTIC: 0,
      MOBILE_SCREEN_REPAIR: 400,
      MOBILE_BATTERY_REPLACEMENT: 200,
    },
  }),
  template({
    code: 'GENERAL',
    businessType: 'general',
    name: 'General Template',
    items: [],
    services: [],
  }),
  template({
    code: 'CUSTOM',
    businessType: 'custom',
    name: 'Custom Template',
    items: [],
    services: [],
  }),
];

export function findTemplateByBusinessType(businessType: string): TemplateRecord | undefined {
  const normalized = businessType
    .toLowerCase()
    .trim()
    .replace(/[\s-]+/g, '_');
  return PREDEFINED_CATALOG_TEMPLATES.find(
    (t) =>
      t.businessType === normalized ||
      t.code.toLowerCase() === normalized ||
      t.code.toLowerCase() === businessType.toLowerCase().trim(),
  );
}
