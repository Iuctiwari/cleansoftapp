import 'reflect-metadata';

import { BadRequestException, NotFoundException } from '@nestjs/common';
import { Types } from 'mongoose';

import {
  ExpenseCategoryStatus,
  ExpensePaymentMethod,
} from '../src/expense/expense.mongoose.schema';
import { ExpenseService } from '../src/expense/expense.service';
import type {
  CreateExpenseCategoryFields,
  CreateExpenseFields,
  ExpenseCategoryRecord,
  ExpenseListQuery,
  ExpensePage,
  ExpenseRecord,
  ExpenseRepository,
  ExpenseScope,
  ExpenseStatistics,
  UpdateExpenseFields,
} from '../src/expense/expense.types';

class InMemoryExpenseRepository implements ExpenseRepository {
  readonly categories: ExpenseCategoryRecord[] = [];
  readonly expenses: ExpenseRecord[] = [];

  createCategory(
    scope: ExpenseScope,
    input: CreateExpenseCategoryFields,
  ): Promise<ExpenseCategoryRecord> {
    const now = new Date();
    const record: ExpenseCategoryRecord = {
      id: new Types.ObjectId().toHexString(),
      tenantId: scope.tenantId,
      categoryName: input.categoryName,
      description: input.description,
      status: input.status ?? ExpenseCategoryStatus.ACTIVE,
      createdAt: now,
      updatedAt: now,
    };
    this.categories.push(record);
    return Promise.resolve(record);
  }

  findCategoryById(
    scope: ExpenseScope,
    id: string,
  ): Promise<ExpenseCategoryRecord | null> {
    return Promise.resolve(
      this.categories.find(
        (c) => c.id === id && c.tenantId === scope.tenantId,
      ) ?? null,
    );
  }

  listCategories(scope: ExpenseScope): Promise<ExpenseCategoryRecord[]> {
    return Promise.resolve(
      this.categories.filter((c) => c.tenantId === scope.tenantId),
    );
  }

  seedDefaultCategoriesIfEmpty(scope: ExpenseScope): Promise<ExpenseCategoryRecord[]> {
    const existing = this.categories.filter((c) => c.tenantId === scope.tenantId);
    if (existing.length > 0) return Promise.resolve(existing);

    const now = new Date();
    const defaults = [
      'Rent',
      'Electricity',
      'Water',
      'Detergent/Materials',
      'Packaging',
      'Salary',
      'Transport',
      'Equipment Maintenance',
      'Marketing',
      'Miscellaneous',
    ];
    for (const name of defaults) {
      this.categories.push({
        id: new Types.ObjectId().toHexString(),
        tenantId: scope.tenantId,
        categoryName: name,
        description: `Default category ${name}`,
        status: ExpenseCategoryStatus.ACTIVE,
        createdAt: now,
        updatedAt: now,
      });
    }
    return Promise.resolve(
      this.categories.filter((c) => c.tenantId === scope.tenantId),
    );
  }

  createExpense(
    scope: ExpenseScope,
    input: CreateExpenseFields,
  ): Promise<ExpenseRecord> {
    const now = new Date();
    const category = this.categories.find((c) => c.id === input.expenseCategoryId);
    const record: ExpenseRecord = {
      id: new Types.ObjectId().toHexString(),
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      expenseCategoryId: input.expenseCategoryId,
      categoryName: category?.categoryName,
      amount: input.amount,
      paymentMethod: input.paymentMethod,
      vendor: input.vendor,
      description: input.description,
      attachment: input.attachment,
      expenseDate: input.expenseDate ?? now,
      recordedBy: scope.actorId,
      createdAt: now,
      updatedAt: now,
    };
    this.expenses.push(record);
    return Promise.resolve(record);
  }

  findById(scope: ExpenseScope, id: string): Promise<ExpenseRecord | null> {
    return Promise.resolve(
      this.expenses.find(
        (e) =>
          e.id === id &&
          e.tenantId === scope.tenantId &&
          e.branchId === scope.branchId,
      ) ?? null,
    );
  }

  listExpenses(
    scope: ExpenseScope,
    query: ExpenseListQuery,
  ): Promise<ExpensePage> {
    const search = query.search?.toLowerCase();
    const matches = this.expenses.filter((e) => {
      if (e.tenantId !== scope.tenantId) return false;
      if (e.branchId !== (query.branchId ?? scope.branchId)) return false;
      if (query.categoryId && e.expenseCategoryId !== query.categoryId) return false;
      if (query.paymentMethod && e.paymentMethod !== query.paymentMethod) return false;
      if (query.startDate && e.expenseDate < query.startDate) return false;
      if (query.endDate && e.expenseDate > query.endDate) return false;
      if (
        search &&
        !e.description.toLowerCase().includes(search) &&
        !e.vendor?.toLowerCase().includes(search)
      ) {
        return false;
      }
      return true;
    });

    const start = (query.page - 1) * query.limit;
    return Promise.resolve({
      items: matches.slice(start, start + query.limit),
      total: matches.length,
      page: query.page,
      limit: query.limit,
    });
  }

  updateExpense(
    scope: ExpenseScope,
    id: string,
    input: UpdateExpenseFields,
  ): Promise<ExpenseRecord | null> {
    const index = this.expenses.findIndex(
      (e) =>
        e.id === id &&
        e.tenantId === scope.tenantId &&
        e.branchId === scope.branchId,
    );
    if (index === -1) return Promise.resolve(null);

    const current = this.expenses[index];
    const category = input.expenseCategoryId
      ? this.categories.find((c) => c.id === input.expenseCategoryId)
      : undefined;

    const updated: ExpenseRecord = {
      ...current,
      expenseCategoryId: input.expenseCategoryId ?? current.expenseCategoryId,
      categoryName: category ? category.categoryName : current.categoryName,
      amount: input.amount ?? current.amount,
      paymentMethod: input.paymentMethod ?? current.paymentMethod,
      vendor: input.vendor !== undefined ? input.vendor ?? undefined : current.vendor,
      description: input.description ?? current.description,
      attachment: input.attachment !== undefined ? input.attachment ?? undefined : current.attachment,
      expenseDate: input.expenseDate ?? current.expenseDate,
      updatedAt: new Date(),
    };
    this.expenses[index] = updated;
    return Promise.resolve(updated);
  }

  statistics(scope: ExpenseScope): Promise<ExpenseStatistics> {
    const branchExpenses = this.expenses.filter(
      (e) => e.tenantId === scope.tenantId && e.branchId === scope.branchId,
    );
    const totalAmount = branchExpenses.reduce((sum, e) => sum + e.amount, 0);
    const categories = new Set(branchExpenses.map((e) => e.expenseCategoryId));
    const byPaymentMethod: Record<string, number> = {};

    for (const e of branchExpenses) {
      byPaymentMethod[e.paymentMethod] =
        (byPaymentMethod[e.paymentMethod] ?? 0) + e.amount;
    }

    return Promise.resolve({
      totalAmount,
      count: branchExpenses.length,
      categoryCount: categories.size,
      byPaymentMethod,
    });
  }
}

describe('ExpenseService', () => {
  let service: ExpenseService;
  let repository: InMemoryExpenseRepository;
  const scope: ExpenseScope = {
    actorId: 'user_123',
    tenantId: '64f0c18f7c4d2f0012ab34aa',
    branchId: 'branch_main',
  };

  beforeEach(() => {
    repository = new InMemoryExpenseRepository();
    service = new ExpenseService(repository);
  });

  describe('Categories', () => {
    it('seeds and returns default categories if none exist', async () => {
      const categories = await service.listCategories(scope);
      expect(categories.length).toBe(10);
      expect(categories.map((c) => c.categoryName)).toContain('Rent');
      expect(categories.map((c) => c.categoryName)).toContain('Electricity');
    });

    it('creates a custom category for the tenant', async () => {
      const category = await service.createCategory(scope, {
        categoryName: 'Office Snacks',
        description: 'Coffee, tea, and cookies',
        status: ExpenseCategoryStatus.ACTIVE,
      });
      expect(category.id).toBeDefined();
      expect(category.categoryName).toBe('Office Snacks');
      expect(category.tenantId).toBe(scope.tenantId);
    });

    it('retrieves category by ID', async () => {
      const created = await service.createCategory(scope, {
        categoryName: 'Machinery',
      });
      const found = await service.getCategoryById(scope, created.id);
      expect(found.id).toBe(created.id);
      expect(found.categoryName).toBe('Machinery');
    });

    it('throws NotFoundException for non-existent category', async () => {
      await expect(
        service.getCategoryById(scope, 'non_existent_id'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('Expenses', () => {
    let category: ExpenseCategoryRecord;

    beforeEach(async () => {
      category = await service.createCategory(scope, {
        categoryName: 'Detergent/Materials',
      });
    });

    it('creates an expense successfully and scopes it to tenant and branch', async () => {
      const expense = await service.createExpense(scope, {
        expenseCategoryId: category.id,
        amount: 2500,
        paymentMethod: ExpensePaymentMethod.CASH,
        vendor: 'SuperClean Chemical Corp',
        description: 'Bulk laundry detergent 50kg',
      });

      expect(expense.id).toBeDefined();
      expect(expense.amount).toBe(2500);
      expect(expense.paymentMethod).toBe(ExpensePaymentMethod.CASH);
      expect(expense.vendor).toBe('SuperClean Chemical Corp');
      expect(expense.tenantId).toBe(scope.tenantId);
      expect(expense.branchId).toBe(scope.branchId);
      expect(expense.recordedBy).toBe(scope.actorId);
    });

    it('rejects an expense with amount <= 0', async () => {
      await expect(
        service.createExpense(scope, {
          expenseCategoryId: category.id,
          amount: 0,
          paymentMethod: ExpensePaymentMethod.CASH,
          description: 'Zero amount test',
        }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        service.createExpense(scope, {
          expenseCategoryId: category.id,
          amount: -50,
          paymentMethod: ExpensePaymentMethod.CASH,
          description: 'Negative amount test',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects an expense with an invalid category ID', async () => {
      await expect(
        service.createExpense(scope, {
          expenseCategoryId: '64f0c18f7c4d2f0012ab9999',
          amount: 100,
          paymentMethod: ExpensePaymentMethod.CARD,
          description: 'Invalid category test',
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('lists and filters expenses by category, payment method, and search term', async () => {
      const otherCat = await service.createCategory(scope, { categoryName: 'Rent' });

      await service.createExpense(scope, {
        expenseCategoryId: category.id,
        amount: 1500,
        paymentMethod: ExpensePaymentMethod.CASH,
        vendor: 'ABC Supplies',
        description: 'Fabric softener',
      });

      await service.createExpense(scope, {
        expenseCategoryId: otherCat.id,
        amount: 30000,
        paymentMethod: ExpensePaymentMethod.BANK_TRANSFER,
        vendor: 'Landlord Properties',
        description: 'Monthly store rent',
      });

      // Filter by category
      const catFilter = await service.listExpenses(scope, {
        page: 1,
        limit: 10,
        categoryId: category.id,
      });
      expect(catFilter.total).toBe(1);
      expect(catFilter.items[0].description).toBe('Fabric softener');

      // Filter by payment method
      const pmFilter = await service.listExpenses(scope, {
        page: 1,
        limit: 10,
        paymentMethod: ExpensePaymentMethod.BANK_TRANSFER,
      });
      expect(pmFilter.total).toBe(1);
      expect(pmFilter.items[0].amount).toBe(30000);

      // Search by vendor
      const searchFilter = await service.listExpenses(scope, {
        page: 1,
        limit: 10,
        search: 'Landlord',
      });
      expect(searchFilter.total).toBe(1);
      expect(searchFilter.items[0].vendor).toBe('Landlord Properties');
    });

    it('updates an existing expense', async () => {
      const created = await service.createExpense(scope, {
        expenseCategoryId: category.id,
        amount: 1000,
        paymentMethod: ExpensePaymentMethod.UPI,
        description: 'Tea and coffee for staff',
      });

      const updated = await service.updateExpense(scope, created.id, {
        amount: 1200,
        description: 'Tea, coffee, and snacks for staff',
      });

      expect(updated.amount).toBe(1200);
      expect(updated.description).toBe('Tea, coffee, and snacks for staff');
    });

    it('returns accurate branch statistics', async () => {
      await service.createExpense(scope, {
        expenseCategoryId: category.id,
        amount: 1000,
        paymentMethod: ExpensePaymentMethod.CASH,
        description: 'Cash expense 1',
      });

      await service.createExpense(scope, {
        expenseCategoryId: category.id,
        amount: 2000,
        paymentMethod: ExpensePaymentMethod.UPI,
        description: 'UPI expense 1',
      });

      const stats = await service.statistics(scope);
      expect(stats.totalAmount).toBe(3000);
      expect(stats.count).toBe(2);
      expect(stats.byPaymentMethod[ExpensePaymentMethod.CASH]).toBe(1000);
      expect(stats.byPaymentMethod[ExpensePaymentMethod.UPI]).toBe(2000);
    });
  });
});
