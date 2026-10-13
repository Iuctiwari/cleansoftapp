import type { OpeningHoursDay } from '../platform/marketplace.database';
import type { ShopCategory } from '../platform/marketplace.types';

/** Days a job normally takes, and how many items fit in one "batch" before it takes a day longer. */
const TURNAROUND: Readonly<Record<ShopCategory, { readonly baseDays: number; readonly batch: number }>> = {
  laundry: { baseDays: 2, batch: 25 },
  dry_cleaning: { baseDays: 3, batch: 12 },
  tailoring: { baseDays: 5, batch: 4 },
  shoe_cleaning: { baseDays: 3, batch: 6 },
  appliance_repair: { baseDays: 3, batch: 2 },
  mobile_repair: { baseDays: 2, batch: 3 },
  vehicle_wash: { baseDays: 1, batch: 4 },
  salon: { baseDays: 1, batch: 10 },
  general: { baseDays: 2, batch: 10 },
  custom: { baseDays: 3, batch: 10 },
};
const MAX_EXTRA_DAYS = 7;
const IST_OFFSET_MS = 330 * 60_000;

export interface DeliveryEstimate {
  /** YYYY-MM-DD, India date */
  readonly deliveryDate: string;
  readonly days: number;
}

/**
 * Suggested delivery date: base days for the kind of work, plus one day for every
 * further batch of items (capped), counted from the collection day and moved on
 * past any day the shop is closed.
 */
export function suggestDelivery(
  category: ShopCategory,
  totalQuantity: number,
  from: Date,
  openingHours: readonly OpeningHoursDay[] = [],
): DeliveryEstimate {
  const rule = TURNAROUND[category] ?? TURNAROUND.general;
  const quantity = Math.max(1, Math.floor(totalQuantity));
  const extra = Math.min(MAX_EXTRA_DAYS, Math.ceil(quantity / rule.batch) - 1);
  const days = rule.baseDays + extra;
  const date = new Date(new Date(from.getTime() + IST_OFFSET_MS).toISOString().slice(0, 10) + 'T00:00:00Z');
  date.setUTCDate(date.getUTCDate() + days);
  for (let guard = 0; guard < 7; guard++) {
    const closed = openingHours.find((day) => day.day === date.getUTCDay())?.closed;
    if (!closed) break;
    date.setUTCDate(date.getUTCDate() + 1);
  }
  return { deliveryDate: date.toISOString().slice(0, 10), days };
}
