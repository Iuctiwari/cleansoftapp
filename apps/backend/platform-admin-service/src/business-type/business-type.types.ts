import type { TenantBusinessType } from './business-type.enum';

export interface BusinessTypeTerminology {
  readonly customerLabel: string;
  readonly orderLabel: string;
  readonly itemLabel: string;
  readonly deliveryLabel: string;
}

export interface BusinessTypeRecord {
  readonly id: string;
  readonly value: TenantBusinessType;
  readonly label: string;
  readonly description?: string;
  readonly isActive: boolean;
  readonly defaultTerminology: BusinessTypeTerminology;
  readonly defaultOrderStatuses: readonly string[];
  readonly defaultServices: readonly string[];
  readonly defaultItemCategories: readonly string[];
  readonly defaultExpenseCategories: readonly string[];
  readonly createdAt: Date;
  readonly updatedAt: Date;
}
