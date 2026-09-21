import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';
import { ModuleKey, RequireModule } from '@nexoraa/tenant-enforcement-client';

import {
  CreateExpenseCategoryDto,
  CreateExpenseDto,
  ExpenseCategoryResponseDto,
  ExpenseErrorResponseDto,
  ExpensePageResponseDto,
  ExpenseResponseDto,
  ExpenseStatisticsResponseDto,
  ListExpensesQueryDto,
  UpdateExpenseDto,
} from './expense.dto';
import { ExpenseEnforcementGuard } from './expense-enforcement.guard';
import { type ExpenseRequest, ExpenseScopeGuard } from './expense.guard';
import { ExpenseService } from './expense.service';
import type {
  ExpenseCategoryRecord,
  ExpensePage,
  ExpenseRecord,
  ExpenseScope,
  ExpenseStatistics,
} from './expense.types';

function getExpenseScope(request: ExpenseRequest): ExpenseScope {
  if (!request.expenseScope) throw new Error('Expense scope guard was not applied');
  return request.expenseScope;
}

@ApiTags('Expenses')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(ExpenseScopeGuard)
@Controller()
export class ExpenseController {
  constructor(private readonly expenseService: ExpenseService) {}

  @Get('expense-categories')
  @ApiOperation({ summary: 'Get available expense categories for the authenticated tenant' })
  @ApiOkResponse({ description: 'List of expense categories.', type: [ExpenseCategoryResponseDto] })
  @ApiUnauthorizedResponse({ type: ExpenseErrorResponseDto })
  @ApiForbiddenResponse({ type: ExpenseErrorResponseDto })
  listCategories(@Req() request: ExpenseRequest): Promise<ExpenseCategoryRecord[]> {
    return this.expenseService.listCategories(getExpenseScope(request));
  }

  @Post('expense-categories')
  @ApiOperation({ summary: 'Create a new expense category for the authenticated tenant' })
  @ApiBody({ type: CreateExpenseCategoryDto })
  @ApiCreatedResponse({ description: 'Category created.', type: ExpenseCategoryResponseDto })
  @ApiBadRequestResponse({ type: ExpenseErrorResponseDto })
  @ApiUnauthorizedResponse({ type: ExpenseErrorResponseDto })
  @ApiForbiddenResponse({ type: ExpenseErrorResponseDto })
  @UseGuards(ExpenseEnforcementGuard)
  @RequireModule(ModuleKey.EXPENSES)
  createCategory(
    @Req() request: ExpenseRequest,
    @Body() body: CreateExpenseCategoryDto,
  ): Promise<ExpenseCategoryRecord> {
    return this.expenseService.createCategory(getExpenseScope(request), body);
  }

  @Get('expense-categories/:id')
  @ApiOperation({ summary: 'Get an expense category by ID' })
  @ApiParam({ name: 'id', description: 'Category ObjectId' })
  @ApiOkResponse({ type: ExpenseCategoryResponseDto })
  @ApiNotFoundResponse({ type: ExpenseErrorResponseDto })
  getCategoryById(
    @Req() request: ExpenseRequest,
    @Param('id') id: string,
  ): Promise<ExpenseCategoryRecord> {
    return this.expenseService.getCategoryById(getExpenseScope(request), id);
  }

  @Post('expenses')
  @ApiOperation({ summary: 'Create an expense for the authenticated tenant and branch' })
  @ApiBody({ type: CreateExpenseDto })
  @ApiCreatedResponse({ description: 'Expense created.', type: ExpenseResponseDto })
  @ApiBadRequestResponse({ type: ExpenseErrorResponseDto })
  @ApiUnauthorizedResponse({ type: ExpenseErrorResponseDto })
  @ApiForbiddenResponse({ type: ExpenseErrorResponseDto })
  @UseGuards(ExpenseEnforcementGuard)
  @RequireModule(ModuleKey.EXPENSES)
  createExpense(
    @Req() request: ExpenseRequest,
    @Body() body: CreateExpenseDto,
  ): Promise<ExpenseRecord> {
    return this.expenseService.createExpense(getExpenseScope(request), body);
  }

  @Get('expenses')
  @ApiOperation({ summary: 'List and filter expenses with server-side pagination' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 20 })
  @ApiQuery({ name: 'categoryId', required: false, type: String })
  @ApiQuery({ name: 'branchId', required: false, type: String })
  @ApiQuery({ name: 'paymentMethod', required: false, type: String })
  @ApiQuery({ name: 'startDate', required: false, type: String })
  @ApiQuery({ name: 'endDate', required: false, type: String })
  @ApiQuery({ name: 'search', required: false, type: String })
  @ApiOkResponse({ description: 'Requested expense page.', type: ExpensePageResponseDto })
  @ApiBadRequestResponse({ type: ExpenseErrorResponseDto })
  @ApiUnauthorizedResponse({ type: ExpenseErrorResponseDto })
  @ApiForbiddenResponse({ type: ExpenseErrorResponseDto })
  listExpenses(
    @Req() request: ExpenseRequest,
    @Query() query: ListExpensesQueryDto,
  ): Promise<ExpensePage> {
    return this.expenseService.listExpenses(getExpenseScope(request), query);
  }

  @Get('expenses/statistics')
  @ApiOperation({ summary: 'Get expense summary and statistics for the authenticated branch' })
  @ApiOkResponse({ type: ExpenseStatisticsResponseDto })
  @ApiUnauthorizedResponse({ type: ExpenseErrorResponseDto })
  @ApiForbiddenResponse({ type: ExpenseErrorResponseDto })
  statistics(@Req() request: ExpenseRequest): Promise<ExpenseStatistics> {
    return this.expenseService.statistics(getExpenseScope(request));
  }

  @Get('expenses/:id')
  @ApiOperation({ summary: 'Get expense details by ID' })
  @ApiParam({ name: 'id', description: 'Expense ObjectId' })
  @ApiOkResponse({ description: 'Expense details.', type: ExpenseResponseDto })
  @ApiNotFoundResponse({ description: 'Expense not found.', type: ExpenseErrorResponseDto })
  getExpenseById(@Req() request: ExpenseRequest, @Param('id') id: string): Promise<ExpenseRecord> {
    return this.expenseService.getExpenseById(getExpenseScope(request), id);
  }

  @Patch('expenses/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update an existing expense' })
  @ApiParam({ name: 'id', description: 'Expense ObjectId' })
  @ApiBody({ type: UpdateExpenseDto })
  @ApiOkResponse({ description: 'Updated expense.', type: ExpenseResponseDto })
  @ApiBadRequestResponse({ type: ExpenseErrorResponseDto })
  @ApiNotFoundResponse({ description: 'Expense not found.', type: ExpenseErrorResponseDto })
  @UseGuards(ExpenseEnforcementGuard)
  @RequireModule(ModuleKey.EXPENSES)
  updateExpense(
    @Req() request: ExpenseRequest,
    @Param('id') id: string,
    @Body() body: UpdateExpenseDto,
  ): Promise<ExpenseRecord> {
    return this.expenseService.updateExpense(getExpenseScope(request), id, body);
  }
}
