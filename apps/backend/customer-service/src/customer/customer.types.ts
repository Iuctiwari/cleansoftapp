import type { PaginatedResult } from '@nexoraa/types';

import type { CustomerType } from './customer.mongoose.schema';

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
  readonly createdAt: Date;
  readonly updatedAt: Date;
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
}
