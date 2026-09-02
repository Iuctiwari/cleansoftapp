/* eslint-disable @typescript-eslint/unbound-method */
import 'reflect-metadata';

import { ExpenseController } from '../src/expense/expense.controller';
import {
  CreateExpenseCategoryDto,
  CreateExpenseDto,
  ListExpensesQueryDto,
  UpdateExpenseDto,
} from '../src/expense/expense.dto';
import type { ExpenseRequest } from '../src/expense/expense.guard';
import {
  ExpenseCategoryStatus,
  ExpensePaymentMethod,
} from '../src/expense/expense.mongoose.schema';
import { ExpenseService } from '../src/expense/expense.service';
import type {
  ExpenseCategoryRecord,
  ExpensePage,
  ExpenseRecord,
  ExpenseScope,
  ExpenseStatistics,
} from '../src/expense/expense.types';

describe('ExpenseController', () => {
  let controller: ExpenseController;
  let service: jest.Mocked<ExpenseService>;

  const mockScope: ExpenseScope = {
    actorId: 'user_123',
    tenantId: '64f0c18f7c4d2f0012ab34aa',
    branchId: 'branch_01',
    roleCode: 'Owner',
    permissions: [],
  };

  const mockRequest: ExpenseRequest = {
    expenseScope: mockScope,
    headers: {},
    query: {},
  };

  beforeEach(() => {
    service = {
      listCategories: jest.fn(),
      createCategory: jest.fn(),
      getCategoryById: jest.fn(),
      createExpense: jest.fn(),
      listExpenses: jest.fn(),
      statistics: jest.fn(),
      getExpenseById: jest.fn(),
      updateExpense: jest.fn(),
    } as unknown as jest.Mocked<ExpenseService>;

    controller = new ExpenseController(service);
  });

  describe('Categories', () => {
    it('should list categories', async () => {
      const categories: ExpenseCategoryRecord[] = [
        {
          id: 'cat_1',
          tenantId: mockScope.tenantId,
          categoryName: 'Rent',
          status: ExpenseCategoryStatus.ACTIVE,
          createdAt: new Date(),
          updatedAt: new Date(),
        },
      ];
      service.listCategories.mockResolvedValue(categories);

      const result = await controller.listCategories(mockRequest);
      expect(result).toBe(categories);
      expect(service.listCategories).toHaveBeenCalledWith(mockScope);
    });

    it('should create category', async () => {
      const dto: CreateExpenseCategoryDto = {
        categoryName: 'Utilities',
        description: 'Power and water',
      };
      const created: ExpenseCategoryRecord = {
        id: 'cat_2',
        tenantId: mockScope.tenantId,
        categoryName: dto.categoryName,
        description: dto.description,
        status: ExpenseCategoryStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      service.createCategory.mockResolvedValue(created);

      const result = await controller.createCategory(mockRequest, dto);
      expect(result).toBe(created);
      expect(service.createCategory).toHaveBeenCalledWith(mockScope, dto);
    });

    it('should get category by id', async () => {
      const category: ExpenseCategoryRecord = {
        id: 'cat_1',
        tenantId: mockScope.tenantId,
        categoryName: 'Rent',
        status: ExpenseCategoryStatus.ACTIVE,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      service.getCategoryById.mockResolvedValue(category);

      const result = await controller.getCategoryById(mockRequest, 'cat_1');
      expect(result).toBe(category);
      expect(service.getCategoryById).toHaveBeenCalledWith(mockScope, 'cat_1');
    });
  });

  describe('Expenses', () => {
    it('should create an expense', async () => {
      const dto: CreateExpenseDto = {
        expenseCategoryId: 'cat_1',
        amount: 2500,
        paymentMethod: ExpensePaymentMethod.CASH,
        vendor: 'ABC',
        description: 'Detergent 25kg',
      };
      const created: ExpenseRecord = {
        id: 'exp_1',
        tenantId: mockScope.tenantId,
        branchId: mockScope.branchId,
        expenseCategoryId: dto.expenseCategoryId,
        amount: dto.amount,
        paymentMethod: dto.paymentMethod,
        vendor: dto.vendor,
        description: dto.description,
        expenseDate: new Date(),
        recordedBy: mockScope.actorId,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      service.createExpense.mockResolvedValue(created);

      const result = await controller.createExpense(mockRequest, dto);
      expect(result).toBe(created);
      expect(service.createExpense).toHaveBeenCalledWith(mockScope, dto);
    });

    it('should list expenses', async () => {
      const query: ListExpensesQueryDto = { page: 1, limit: 10 };
      const pageResult: ExpensePage = {
        items: [],
        total: 0,
        page: 1,
        limit: 10,
      };
      service.listExpenses.mockResolvedValue(pageResult);

      const result = await controller.listExpenses(mockRequest, query);
      expect(result).toBe(pageResult);
      expect(service.listExpenses).toHaveBeenCalledWith(mockScope, query);
    });

    it('should get statistics', async () => {
      const stats: ExpenseStatistics = {
        totalAmount: 15000,
        count: 5,
        categoryCount: 3,
        byPaymentMethod: { Cash: 5000, UPI: 10000 },
      };
      service.statistics.mockResolvedValue(stats);

      const result = await controller.statistics(mockRequest);
      expect(result).toBe(stats);
      expect(service.statistics).toHaveBeenCalledWith(mockScope);
    });

    it('should get expense by id', async () => {
      const expense: ExpenseRecord = {
        id: 'exp_1',
        tenantId: mockScope.tenantId,
        branchId: mockScope.branchId,
        expenseCategoryId: 'cat_1',
        amount: 2500,
        paymentMethod: ExpensePaymentMethod.CASH,
        description: 'Detergent 25kg',
        expenseDate: new Date(),
        recordedBy: mockScope.actorId,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      service.getExpenseById.mockResolvedValue(expense);

      const result = await controller.getExpenseById(mockRequest, 'exp_1');
      expect(result).toBe(expense);
      expect(service.getExpenseById).toHaveBeenCalledWith(mockScope, 'exp_1');
    });

    it('should update an expense', async () => {
      const dto: UpdateExpenseDto = { amount: 3000 };
      const updated: ExpenseRecord = {
        id: 'exp_1',
        tenantId: mockScope.tenantId,
        branchId: mockScope.branchId,
        expenseCategoryId: 'cat_1',
        amount: 3000,
        paymentMethod: ExpensePaymentMethod.CASH,
        description: 'Updated desc',
        expenseDate: new Date(),
        recordedBy: mockScope.actorId,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      service.updateExpense.mockResolvedValue(updated);

      const result = await controller.updateExpense(mockRequest, 'exp_1', dto);
      expect(result).toBe(updated);
      expect(service.updateExpense).toHaveBeenCalledWith(mockScope, 'exp_1', dto);
    });
  });
});
