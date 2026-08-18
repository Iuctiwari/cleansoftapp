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

export interface OrderAssignmentRecord {
  readonly id: string;
  readonly orderId: string;
  readonly assignedTo: string;
  readonly assignedBy: string;
  readonly dueDate?: Date;
  readonly status: string;
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
}

export type OrderPage = PaginatedResult<OrderRecord>;

export interface OrderRepository {
  create(scope: OrderScope, input: CreateOrderRecord): Promise<OrderRecord>;
  findById(scope: OrderScope, id: string, assignedTo?: string): Promise<OrderRecord | null>;
  list(scope: OrderScope, query: OrderListQuery): Promise<OrderPage>;
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
  ): Promise<OrderRecord | null>;
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
