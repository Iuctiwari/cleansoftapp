export type PaymentMethod = 'Cash' | 'Card' | 'UPI';

export interface PaymentScope {
  readonly actorId: string;
  readonly authorization: string;
  readonly branchId: string;
  readonly permissions: readonly string[];
  readonly roleCode: string;
  readonly tenantId: string;
}

export interface PaymentRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  paymentScope?: PaymentScope;
}

export interface CreateAdvancePaymentInput {
  readonly orderId?: unknown;
  readonly customerId?: unknown;
  readonly amountMinor?: unknown;
  readonly currency?: unknown;
  readonly method?: unknown;
  readonly paymentType?: unknown;
}

export type PaymentType = 'Advance';
export type PaymentTransactionStatus = 'Pending' | 'Successful' | 'Failed';

export interface PaymentListQuery {
  readonly page: number;
  readonly limit: number;
  readonly sortDirection: 1 | -1;
  readonly status?: PaymentTransactionStatus;
  readonly paymentType?: PaymentType;
  readonly customerId?: string;
  readonly orderId?: string;
}

export interface PaymentRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly orderId: string;
  readonly customerId: string;
  readonly paymentNumber: string;
  readonly paymentType: PaymentType;
  readonly method: PaymentMethod;
  readonly amountMinor: number;
  readonly currency: string;
  readonly status: PaymentTransactionStatus;
  readonly recordedBy: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
  /** Resolved from the referenced order's customer snapshot when Order Service is reachable. */
  readonly customerName?: string;
  /** Resolved from the referenced order when Order Service is reachable. */
  readonly orderNumber?: string;
}

export interface PaymentStatistics {
  readonly todayCollectedMinor: number;
  readonly yesterdayCollectedMinor: number;
  readonly todayCollectedCount: number;
  readonly totalBills: number;
  readonly successfulBills: number;
}
