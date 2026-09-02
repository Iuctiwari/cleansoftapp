import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Permissions, hasPermission, isBranchManagerRole, isOwnerRole } from '@nexoraa/shared';

import type {
  CreateExpenseCategoryDto,
  CreateExpenseDto,
  ListExpensesQueryDto,
  UpdateExpenseDto,
} from './expense.dto';
import {
  EXPENSE_REPOSITORY,
  type ExpenseCategoryRecord,
  type ExpenseListQuery,
  type ExpensePage,
  type ExpenseRecord,
  type ExpenseRepository,
  type ExpenseScope,
  type ExpenseStatistics,
} from './expense.types';

@Injectable()
export class ExpenseService {
  constructor(
    @Inject(EXPENSE_REPOSITORY)
    private readonly expenseRepository: ExpenseRepository,
  ) {}

  async createCategory(
    scope: ExpenseScope,
    dto: CreateExpenseCategoryDto,
  ): Promise<ExpenseCategoryRecord> {
    this.assertOwner(scope);
    return this.expenseRepository.createCategory(scope, {
      categoryName: dto.categoryName,
      description: dto.description,
      status: dto.status,
    });
  }

  async listCategories(scope: ExpenseScope): Promise<ExpenseCategoryRecord[]> {
    this.assertRead(scope);
    return this.expenseRepository.seedDefaultCategoriesIfEmpty(scope);
  }

  async getCategoryById(scope: ExpenseScope, id: string): Promise<ExpenseCategoryRecord> {
    this.assertRead(scope);
    const category = await this.expenseRepository.findCategoryById(scope, id);
    if (!category) throw new NotFoundException('Expense category not found');
    return category;
  }

  async createExpense(scope: ExpenseScope, dto: CreateExpenseDto): Promise<ExpenseRecord> {
    this.assertCreate(scope);
    if (dto.amount <= 0) {
      throw new BadRequestException('Expense amount must be greater than zero');
    }

    const category = await this.expenseRepository.findCategoryById(scope, dto.expenseCategoryId);
    if (!category) {
      throw new BadRequestException('Invalid expense category for the current tenant');
    }

    return this.expenseRepository.createExpense(scope, {
      expenseCategoryId: dto.expenseCategoryId,
      amount: dto.amount,
      paymentMethod: dto.paymentMethod,
      vendor: dto.vendor,
      description: dto.description,
      attachment: dto.attachment,
      expenseDate: dto.expenseDate ? new Date(dto.expenseDate) : undefined,
    });
  }

  async listExpenses(scope: ExpenseScope, query: ListExpensesQueryDto): Promise<ExpensePage> {
    this.assertRead(scope);
    const listQuery: ExpenseListQuery = {
      page: query.page,
      limit: query.limit,
      categoryId: query.categoryId,
      branchId: query.branchId,
      paymentMethod: query.paymentMethod,
      startDate: query.startDate ? new Date(query.startDate) : undefined,
      endDate: query.endDate ? new Date(query.endDate) : undefined,
      search: query.search,
    };
    return this.expenseRepository.listExpenses(scope, listQuery);
  }

  async getExpenseById(scope: ExpenseScope, id: string): Promise<ExpenseRecord> {
    this.assertRead(scope);
    const expense = await this.expenseRepository.findById(scope, id);
    if (!expense) throw new NotFoundException('Expense not found');
    return expense;
  }

  async updateExpense(
    scope: ExpenseScope,
    id: string,
    dto: UpdateExpenseDto,
  ): Promise<ExpenseRecord> {
    this.assertOwner(scope);
    if (dto.amount !== undefined && dto.amount <= 0) {
      throw new BadRequestException('Expense amount must be greater than zero');
    }

    if (dto.expenseCategoryId) {
      const category = await this.expenseRepository.findCategoryById(scope, dto.expenseCategoryId);
      if (!category) {
        throw new BadRequestException('Invalid expense category for the current tenant');
      }
    }

    const updated = await this.expenseRepository.updateExpense(scope, id, {
      expenseCategoryId: dto.expenseCategoryId,
      amount: dto.amount,
      paymentMethod: dto.paymentMethod,
      vendor: dto.vendor,
      description: dto.description,
      attachment: dto.attachment,
      expenseDate: dto.expenseDate ? new Date(dto.expenseDate) : undefined,
    });

    if (!updated) throw new NotFoundException('Expense not found');
    return updated;
  }

  async statistics(scope: ExpenseScope): Promise<ExpenseStatistics> {
    this.assertRead(scope);
    return this.expenseRepository.statistics(scope);
  }

  private assertRead(scope: ExpenseScope): void {
    if (
      !(isOwnerRole(scope.roleCode) || isBranchManagerRole(scope.roleCode)) ||
      !hasPermission(scope.roleCode, scope.permissions, Permissions.expensesRead)
    ) {
      throw new ForbiddenException('Expense read permission is required');
    }
  }

  private assertCreate(scope: ExpenseScope): void {
    if (
      !(isOwnerRole(scope.roleCode) || isBranchManagerRole(scope.roleCode)) ||
      !hasPermission(scope.roleCode, scope.permissions, Permissions.expensesWrite)
    ) {
      throw new ForbiddenException('Expense create permission is required');
    }
  }

  private assertOwner(scope: ExpenseScope): void {
    if (!isOwnerRole(scope.roleCode)) {
      throw new ForbiddenException('Owner permission is required');
    }
  }
}
