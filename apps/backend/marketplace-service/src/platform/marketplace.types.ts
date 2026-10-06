/** Same values as tenant-service's TenantBusinessType. */
export const SHOP_CATEGORIES = [
  'laundry',
  'dry_cleaning',
  'tailoring',
  'shoe_cleaning',
  'appliance_repair',
  'mobile_repair',
  'vehicle_wash',
  'salon',
  'general',
  'custom',
] as const;
export type ShopCategory = (typeof SHOP_CATEGORIES)[number];

/** Category chips shown to customers, in display order. */
export const CATEGORY_LABELS: Readonly<Record<ShopCategory, string>> = {
  laundry: 'Laundry',
  dry_cleaning: 'Dry cleaning',
  tailoring: 'Tailoring',
  shoe_cleaning: 'Shoe cleaning',
  appliance_repair: 'Appliance repair',
  mobile_repair: 'Mobile repair',
  vehicle_wash: 'Vehicle wash',
  salon: 'Salon',
  general: 'General services',
  custom: 'Other services',
};

/**
 * How a shop serves customers:
 * visit_shop — the customer comes to the shop (salon appointment, drop off a repair);
 * home_service — the shop comes to the customer;
 * pickup_drop — the shop collects and returns items (laundry).
 */
export const SERVICE_MODES = ['visit_shop', 'home_service', 'pickup_drop'] as const;
export type ServiceMode = (typeof SERVICE_MODES)[number];

export const ADDRESS_LABELS = ['Home', 'Work', 'Other'] as const;
export type AddressLabel = (typeof ADDRESS_LABELS)[number];

export interface GeoPoint {
  readonly latitude: number;
  readonly longitude: number;
}

/** A signed-in marketplace customer, resolved through auth-service. */
export interface ConsumerPrincipal {
  readonly consumerId: string;
  readonly displayName: string;
  readonly email: string;
  readonly mobileNumber: string;
}

/** A signed-in shop user, scoped to the branch they are working in. */
export interface ShopPrincipal {
  readonly actorId: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
  /** The caller's own bearer header, forwarded when checking their orders. */
  readonly authorization: string;
}

export interface MarketplaceRequest {
  consumer?: ConsumerPrincipal;
  shop?: ShopPrincipal;
  headers: Record<string, string | string[] | undefined>;
}
