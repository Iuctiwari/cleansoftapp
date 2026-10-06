import type { PaginatedResult } from '@nexoraa/types';

import type { OrderPaymentStatus, OrderStatus } from './enums';

export const ORDER_REPOSITORY = Symbol('ORDER_REPOSITORY');
export const ORDER_DEPENDENCIES = Symbol('ORDER_DEPENDENCIES');

export const CATALOG_PRICING_TYPES = [
  'PerItem',
  'PerKg',
  'PerPair',
  'PerHour',
  'Fixed',
  'Custom',
] as const;
export type CatalogPricingType = (typeof CATALOG_PRICING_TYPES)[number];

export interface OrderScope {
  readonly actorId: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
  readonly authorization: string;
}

export interface OrderItemRecord {
  readonly id: string;
  readonly itemCategoryId: string;
  readonly itemCategorySnapshot: Record<string, unknown>;
  readonly serviceId: string;
  readonly serviceSnapshot: Record<string, unknown>;
  readonly quantity?: number;
  readonly weight?: number;
  readonly unitPrice: number;
  readonly discount: number;
  readonly tax: number;
  readonly lineTotal: number;
  readonly processingStatus?: string;
  readonly notes?: string;
}

export const DECLINE_REQUEST_STATUSES = ['Pending', 'Approved', 'Denied'] as const;
export type DeclineRequestStatus = (typeof DECLINE_REQUEST_STATUSES)[number];

/**
 * A worker's request to be taken off an order. Workers cannot drop an order
 * themselves: the order stays theirs until an Owner/Branch Manager approves
 * (order goes back to the unassigned pool) or denies (worker keeps it).
 */
/** Thrown inside the approve transaction to roll it back when the order already moved on. */
export class DeclineConflictError extends Error {
  constructor() {
    super('Order changed since the decline request was made');
  }
}

export interface DeclineRequestRecord {
  readonly reason: string;
  readonly status: DeclineRequestStatus;
  readonly requestedBy: string;
  readonly requestedAt: Date;
  readonly resolvedBy?: string;
  readonly resolvedAt?: Date;
  readonly responseNote?: string;
}

export const ORDER_NOTE_KINDS = ['General', 'Damage'] as const;
export type OrderNoteKind = (typeof ORDER_NOTE_KINDS)[number];

/** Append-only note on an order, e.g. a worker reporting a damaged item. */
export interface OrderNoteRecord {
  readonly id: string;
  readonly text: string;
  readonly kind: OrderNoteKind;
  /** Set when the note is about one specific line item of the order. */
  readonly itemId?: string;
  readonly authorId: string;
  readonly authorRole: string;
  readonly createdAt: Date;
}

export interface OrderAssignmentRecord {
  readonly id: string;
  readonly orderId: string;
  readonly assignedTo: string;
  readonly assignedBy: string;
  readonly dueDate?: Date;
  readonly note?: string;
  readonly status: string;
  readonly declineRequest?: DeclineRequestRecord;
  readonly createdAt: Date;
  readonly updatedAt: Date;
  readonly version: number;
}

export interface OrderRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly orderNumber: string;
  readonly customerId: string;
  readonly customerSnapshot: Record<string, unknown>;
  readonly status: OrderStatus;
  readonly paymentStatus: OrderPaymentStatus;
  readonly items: readonly OrderItemRecord[];
  readonly subtotal: number;
  readonly discount: number;
  readonly discountPercentage: number;
  readonly tax: number;
  readonly grandTotal: number;
  readonly paidAmount: number;
  readonly outstandingAmount: number;
  readonly expectedDeliveryDate?: Date;
  readonly deliveryDate?: Date;
  readonly assignedTo?: string;
  readonly assignment?: OrderAssignmentRecord;
  readonly notes?: readonly OrderNoteRecord[];
  readonly cancelReason?: string;
  readonly createdBy: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
  readonly version: number;
}

export interface StatusHistoryRecord {
  readonly id: string;
  readonly orderId: string;
  readonly previousStatus: OrderStatus;
  readonly newStatus: OrderStatus;
  readonly changedBy: string;
  readonly note?: string;
  readonly timestamp: Date;
}

export interface PersistedOrderItem {
  readonly itemCategoryId: string;
  readonly itemCategorySnapshot: Record<string, unknown>;
  readonly serviceId: string;
  readonly serviceSnapshot: Record<string, unknown>;
  readonly quantity?: number;
  readonly weight?: number;
  readonly unitPrice: number;
  readonly discount: number;
  readonly tax: number;
  readonly lineTotal: number;
  readonly notes?: string;
}

export interface OrderTotals {
  readonly items: readonly PersistedOrderItem[];
  readonly subtotal: number;
  readonly discount: number;
  readonly discountPercentage: number;
  readonly tax: number;
  readonly grandTotal: number;
  readonly paidAmount: number;
  readonly outstandingAmount: number;
}

export interface CreateOrderRecord extends OrderTotals {
  readonly branchCode: string;
  readonly customerId: string;
  readonly customerSnapshot: Record<string, unknown>;
  readonly expectedDeliveryDate?: Date;
  readonly assignedTo?: string;
}

export interface UpdateOrderRecord extends OrderTotals {
  readonly expectedDeliveryDate?: Date;
}

export interface OrderListQuery {
  readonly page: number;
  readonly limit: number;
  readonly search?: string;
  readonly status?: OrderStatus;
  readonly paymentStatus?: OrderPaymentStatus;
  readonly customerId?: string;
  readonly sortBy:
    | 'createdAt'
    | 'updatedAt'
    | 'orderNumber'
    | 'grandTotal'
    | 'expectedDeliveryDate';
  readonly sortDirection: 1 | -1;
  readonly assignedTo?: string;
  /** Only orders nobody is assigned to that can still be assigned (Received/Rejected). */
  readonly unassigned?: boolean;
  /** Only orders past their expected delivery date that are not Ready/delivered/cancelled. */
  readonly overdueBefore?: Date;
}

/** Per-worker task counts for the owner's Worker Tasks screen. */
export interface WorkerWorkload {
  readonly workerId: string;
  readonly assigned: number;
  readonly accepted: number;
  readonly inProgress: number;
  readonly ready: number;
  readonly outForDelivery: number;
  readonly deliveredToday: number;
  readonly deliveredTotal: number;
  /** Open = assigned + accepted + inProgress (work still to be done). */
  readonly open: number;
  readonly overdue: number;
  readonly pendingDeclineRequests: number;
  readonly damageReports: number;
}

export interface WorkloadSummary {
  readonly workers: readonly WorkerWorkload[];
  readonly unassigned: number;
  readonly pendingDeclineRequests: number;
  readonly generatedAt: Date;
}

export interface NewOrderNote {
  readonly id: string;
  readonly text: string;
  readonly kind: OrderNoteKind;
  readonly itemId?: string;
  readonly authorId: string;
  readonly authorRole: string;
  readonly createdAt: Date;
}

export type OrderPage = PaginatedResult<OrderRecord>;

export interface OrderStatistics {
  readonly totalOrders: number;
  readonly todayOrders: number;
  readonly yesterdayOrders: number;
  readonly outstandingTotal: number;
  readonly outstandingCustomerCount: number;
  readonly statusBreakdown: Readonly<Record<string, number>>;
}

/**
 * Tenant-wide (all branches), for the Company Admin panel — see TenantOrderSummaryController.
 * "outstandingMinor" is the true accounts-receivable balance: the live sum of every one of
 * this tenant's orders' own outstandingAmount (grandTotal - paidAmount, kept in sync by
 * applyPaymentProjection whenever payment-service applies a payment) — this is the
 * authoritative source, unlike payment-service's pendingPaymentsMinor which only reflects
 * payments it has itself received or attempted.
 */
export interface TenantOrderSummary {
  readonly totalOrders: number;
  readonly ordersThisMonth: number;
  readonly lastOrderDate: string | null;
  readonly outstandingMinor: number;
}

export interface OrderRepository {
  create(scope: OrderScope, input: CreateOrderRecord): Promise<OrderRecord>;
  findById(scope: OrderScope, id: string, assignedTo?: string): Promise<OrderRecord | null>;
  list(scope: OrderScope, query: OrderListQuery): Promise<OrderPage>;
  /** No scope needed — internal/system-level query (see PlatformAdminInternalGuard). */
  getSummaryForTenant(tenantId: string): Promise<TenantOrderSummary>;
  statistics(
    scope: OrderScope,
    filters: { readonly assignedTo?: string; readonly customerId?: string },
  ): Promise<OrderStatistics>;
  update(
    scope: OrderScope,
    id: string,
    status: OrderStatus,
    input: UpdateOrderRecord,
  ): Promise<OrderRecord | null>;
  transition(
    scope: OrderScope,
    id: string,
    previousStatus: OrderStatus,
    newStatus: OrderStatus,
    note?: string,
    cancelReason?: string,
  ): Promise<OrderRecord | null>;
  assign(
    scope: OrderScope,
    id: string,
    assignedTo: string,
    dueDate?: Date,
    note?: string,
  ): Promise<OrderRecord | null>;
  acceptAssignment(scope: OrderScope, id: string): Promise<OrderRecord | null>;
  /** Records a Pending decline request; null when the worker no longer holds the order or one is already pending. */
  requestDecline(
    scope: OrderScope,
    id: string,
    workerId: string,
    reason: string,
  ): Promise<OrderRecord | null>;
  /**
   * Approve: unassigns the order and returns it to Received. Deny: the worker keeps it.
   * Null when there is no pending request (e.g. resolved concurrently).
   */
  resolveDecline(
    scope: OrderScope,
    id: string,
    approve: boolean,
    responseNote?: string,
  ): Promise<OrderRecord | null>;
  listPendingDeclines(scope: OrderScope): Promise<readonly OrderRecord[]>;
  addNote(scope: OrderScope, id: string, note: NewOrderNote): Promise<OrderRecord | null>;
  workload(scope: OrderScope, now: Date): Promise<WorkloadSummary>;
  /** Open (assigned/accepted/in-progress) order counts for the given workers. */
  openCounts(
    scope: OrderScope,
    workerIds: readonly string[],
  ): Promise<Readonly<Record<string, number>>>;
  rejectAssignment(scope: OrderScope, id: string, reason?: string): Promise<OrderRecord | null>;
  history(scope: OrderScope, orderId: string): Promise<readonly StatusHistoryRecord[]>;
  applyPaymentProjection(
    scope: OrderScope,
    id: string,
    paymentId: string,
    amount: number,
  ): Promise<OrderRecord | null>;
}

export interface CatalogQuote {
  readonly itemCategorySnapshot: Record<string, unknown>;
  readonly serviceSnapshot: Record<string, unknown>;
  readonly pricingType: CatalogPricingType;
  readonly unitPrice: number;
  readonly taxPercent: number;
}

export interface BranchReference {
  readonly branchId: string;
  readonly code: string;
}

export interface CustomerSnapshot extends Record<string, unknown> {
  readonly customerId: string;
  readonly name: string;
  readonly mobile?: string;
  readonly email?: string;
  readonly address?: string;
  readonly customerType: string;
}

export interface OrderDependencies {
  resolveBranch(scope: OrderScope): Promise<BranchReference>;
  resolveCustomer(scope: OrderScope, customerId: string): Promise<CustomerSnapshot>;
  validateCatalogReference(
    scope: OrderScope,
    serviceId: string,
    itemCategoryId: string,
  ): Promise<void>;
  quoteCatalog(scope: OrderScope, serviceId: string, itemCategoryId: string): Promise<CatalogQuote>;
  assertStaffEligible(scope: OrderScope, staffId: string): Promise<void>;
}
