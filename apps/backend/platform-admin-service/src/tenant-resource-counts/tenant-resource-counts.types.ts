/** null in any field below means that lookup failed/timed out/service is
 *  down — not that the real value is zero or unavailable-by-design. */
export interface TenantOrderSummary {
  readonly totalOrders: number;
  readonly ordersThisMonth: number;
  readonly lastOrderDate: string | null;
  /** True accounts-receivable balance — live sum of every order's own outstandingAmount. */
  readonly outstandingMinor: number;
}

export interface TenantPaymentSummary {
  readonly totalRevenueMinor: number;
  readonly revenueThisMonthMinor: number;
  /** Payments recorded but not yet confirmed — NOT accounts-receivable. See TenantOrderSummary.outstandingMinor for that. */
  readonly pendingPaymentsMinor: number;
}

export interface TenantResourceCounts {
  readonly branchCount: number | null;
  readonly staffCount: number | null;
  readonly customerCount: number | null;
  readonly orderSummary: TenantOrderSummary | null;
  readonly paymentSummary: TenantPaymentSummary | null;
}
