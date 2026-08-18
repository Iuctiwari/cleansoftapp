import type { PaginatedResult } from '@nexoraa/types';

import type {
  ExpenseCategoryStatus,
  ExpensePaymentMethod,
} from './expense.mongoose.schema';

export const EXPENSE_REPOSITORY = Symbol('EXPENSE_REPOSITORY');

export interface ExpenseScope {
  readonly actorId: string;
  readonly tenantId: string;
  readonly branchId: string;
}

export interface ExpenseCategoryRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly categoryName: string;
  readonly description?: string;
  readonly status: ExpenseCategoryStatus;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface CreateExpenseCategoryFields {
  readonly categoryName: string;
  readonly description?: string;
  readonly status?: ExpenseCategoryStatus;
}

export interface ExpenseRecord {
  readonly id: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly expenseCategoryId: string;
  readonly categoryName?: string;
  readonly amount: number;
  readonly paymentMethod: ExpensePaymentMethod;
  readonly vendor?: string;
  readonly description: string;
  readonly attachment?: string;
  readonly expenseDate: Date;
  readonly recordedBy: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface CreateExpenseFields {
  readonly expenseCategoryId: string;
  readonly amount: number;
  readonly paymentMethod: ExpensePaymentMethod;
  readonly vendor?: string;
  readonly description: string;
  readonly attachment?: string;
  readonly expenseDate?: Date;
}

export interface UpdateExpenseFields {
  readonly expenseCategoryId?: string;
  readonly amount?: number;
  readonly paymentMethod?: ExpensePaymentMethod;
  readonly vendor?: string | null;
  readonly description?: string;
  readonly attachment?: string | null;
  readonly expenseDate?: Date;
}

export interface ExpenseListQuery {
  readonly page: number;
  readonly limit: number;
  readonly categoryId?: string;
  readonly branchId?: string;
  readonly paymentMethod?: ExpensePaymentMethod;
  readonly startDate?: Date;
  readonly endDate?: Date;
  readonly search?: string;
}

export type ExpensePage = Omit<PaginatedResult<ExpenseRecord>, 'totalPages'>;

export interface ExpenseStatistics {
  readonly totalAmount: number;
  readonly count: number;
  readonly categoryCount: number;
  readonly byPaymentMethod: Record<string, number>;
}

export interface ExpenseRepository {
  createCategory(
    scope: ExpenseScope,
    input: CreateExpenseCategoryFields,
  ): Promise<ExpenseCategoryRecord>;
  findCategoryById(
    scope: ExpenseScope,
    id: string,
  ): Promise<ExpenseCategoryRecord | null>;
  listCategories(scope: ExpenseScope): Promise<ExpenseCategoryRecord[]>;
  seedDefaultCategoriesIfEmpty(scope: ExpenseScope): Promise<ExpenseCategoryRecord[]>;
  createExpense(
    scope: ExpenseScope,
    input: CreateExpenseFields,
  ): Promise<ExpenseRecord>;
  findById(scope: ExpenseScope, id: string): Promise<ExpenseRecord | null>;
  listExpenses(scope: ExpenseScope, query: ExpenseListQuery): Promise<ExpensePage>;
  updateExpense(
    scope: ExpenseScope,
    id: string,
    input: UpdateExpenseFields,
  ): Promise<ExpenseRecord | null>;
  statistics(scope: ExpenseScope): Promise<ExpenseStatistics>;
}
