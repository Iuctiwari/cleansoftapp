import type { PaginatedResult } from '@nexoraa/types';

import type { CustomerSource, CustomerType } from './customer.mongoose.schema';

export const CUSTOMER_REPOSITORY = Symbol('CUSTOMER_REPOSITORY');

export interface CustomerScope {
  readonly actorId: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
}

export interface CustomerRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly name: string;
  readonly mobile?: string;
  readonly email?: string;
  readonly address?: string;
  readonly customerType: CustomerType;
  readonly joiningDate: Date;
  readonly totalOrders: number;
  readonly totalSpent: number;
  readonly outstandingBalance: number;
  readonly lastOrderDate: Date | null;
  /** "online" when the customer first came through the marketplace app. */
  readonly source: CustomerSource;
  /** Marketplace account linked to this customer, if any. */
  readonly consumerId?: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

/** A marketplace customer who sent a request to this branch. */
export interface OnlineCustomerInput {
  readonly consumerId: string;
  readonly name: string;
  /** 10-digit Indian mobile number. */
  readonly mobile: string;
  readonly email?: string;
  readonly address?: string;
}

export interface OnlineCustomerLink {
  readonly customerId: string;
  /** existing: already linked · linked: matched a shop-entered customer by mobile · created: new */
  readonly outcome: 'existing' | 'linked' | 'created';
}

export interface CustomerMutableFields {
  readonly name?: string;
  readonly mobile?: string | null;
  readonly email?: string | null;
  readonly address?: string | null;
  readonly customerType?: CustomerType;
  readonly joiningDate?: Date;
}

export interface CreateCustomerFields extends CustomerMutableFields {
  readonly name: string;
  readonly customerType: CustomerType;
}

export interface CustomerListQuery {
  readonly page: number;
  readonly limit: number;
  readonly search?: string;
  readonly source?: CustomerSource;
}

export type CustomerPage = Omit<PaginatedResult<CustomerRecord>, 'totalPages'>;

export interface CustomerStatistics {
  readonly total: number;
  readonly active: number;
  readonly outstanding: number;
}

export interface CustomerRepository {
  create(scope: CustomerScope, input: CreateCustomerFields): Promise<CustomerRecord>;
  findById(scope: CustomerScope, id: string): Promise<CustomerRecord | null>;
  list(scope: CustomerScope, query: CustomerListQuery): Promise<CustomerPage>;
  statistics(scope: CustomerScope): Promise<CustomerStatistics>;
  /** Tenant-wide (all branches), no scope needed — internal/system-level
   *  query (see PlatformAdminInternalGuard), used by platform-admin-service's
   *  Company Admin panel (tenant detail screen). */
  countForTenant(tenantId: string): Promise<number>;
  update(
    scope: CustomerScope,
    id: string,
    input: CustomerMutableFields,
  ): Promise<CustomerRecord | null>;
  softDelete(scope: CustomerScope, id: string): Promise<boolean>;
  /** Internal: find or create the branch's customer record for a marketplace customer. */
  linkOnlineCustomer(
    tenantId: string,
    branchId: string,
    input: OnlineCustomerInput,
  ): Promise<OnlineCustomerLink>;
}
