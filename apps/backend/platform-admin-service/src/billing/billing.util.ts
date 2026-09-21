import { BillingCycle } from '../subscription/subscription.types';

/** Advances `date` by one billing cycle (calendar month or calendar year). */
export function addBillingCycle(date: Date, billingCycle: BillingCycle): Date {
  const result = new Date(date.getTime());
  if (billingCycle === BillingCycle.ANNUAL) {
    result.setFullYear(result.getFullYear() + 1);
  } else {
    result.setMonth(result.getMonth() + 1);
  }
  return result;
}

/** Razorpay receipts must be unique and at most 40 characters. */
export function buildReceipt(tenantId: string): string {
  return `b_${tenantId}_${Date.now().toString(36)}`;
}
