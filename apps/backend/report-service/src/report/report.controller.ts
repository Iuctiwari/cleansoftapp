import { Controller, Get, Query, Req, UseGuards } from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiForbiddenResponse,
  ApiInternalServerErrorResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import {
  BranchPerformanceResponseDto,
  ReportExpensePageResponseDto,
  ReportListQueryDto,
  ReportOrderPageResponseDto,
  ReportPaymentPageResponseDto,
  ReportSummaryQueryDto,
  ReportSummaryResponseDto,
} from './report.dto';
import { type ReportRequest, ReportScopeGuard } from './report.guard';
import { ReportService, type ReportSummary } from './report.service';
import type {
  BranchPerformanceReport,
  ExpenseReportPage,
  OrderReportPage,
  PaymentReportPage,
  ReportScope,
} from './report.types';

function scope(request: ReportRequest): ReportScope {
  if (!request.reportScope) throw new Error('Report scope guard was not applied');
  return request.reportScope;
}

@ApiTags('Reports')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(ReportScopeGuard)
@Controller({ path: 'reports', version: '1' })
export class ReportController {
  constructor(private readonly reportService: ReportService) {}

  @Get('branch-performance')
  @ApiOperation({ summary: 'Get all tenant branches with calculated performance metrics' })
  @ApiOkResponse({
    description: 'Tenant-scoped branch performance for the selected period.',
    type: BranchPerformanceResponseDto,
  })
  @ApiBadRequestResponse({ description: 'Report query validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT and active branch are required.' })
  @ApiForbiddenResponse({ description: 'Tenant owner access is required.' })
  @ApiInternalServerErrorResponse({ description: 'Report query failed unexpectedly.' })
  branchPerformance(
    @Req() request: ReportRequest,
    @Query() query: ReportSummaryQueryDto,
  ): Promise<BranchPerformanceReport> {
    return this.reportService.branchPerformance(scope(request), query);
  }

  @Get('summary')
  @ApiOperation({ summary: 'Get branch-scoped report KPIs and chart data' })
  @ApiOkResponse({
    description: 'Report summary for the selected period.',
    type: ReportSummaryResponseDto,
  })
  @ApiBadRequestResponse({ description: 'Report query validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT and active branch are required.' })
  @ApiForbiddenResponse({ description: 'Tenant or branch authorization failed.' })
  @ApiInternalServerErrorResponse({ description: 'Report query failed unexpectedly.' })
  summary(
    @Req() request: ReportRequest,
    @Query() query: ReportSummaryQueryDto,
  ): Promise<ReportSummary> {
    return this.reportService.summary(scope(request), query);
  }

  @Get('orders')
  @ApiOperation({ summary: 'Get branch-scoped orders and calculated order metrics' })
  @ApiOkResponse({ description: 'Scoped order report page.', type: ReportOrderPageResponseDto })
  @ApiBadRequestResponse({ description: 'Report query validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT and active branch are required.' })
  @ApiForbiddenResponse({ description: 'Tenant or branch authorization failed.' })
  @ApiInternalServerErrorResponse({ description: 'Report query failed unexpectedly.' })
  orders(
    @Req() request: ReportRequest,
    @Query() query: ReportListQueryDto,
  ): Promise<OrderReportPage> {
    return this.reportService.orders(scope(request), query);
  }

  @Get('payments')
  @ApiOperation({ summary: 'Get branch-scoped payments and calculated payment metrics' })
  @ApiOkResponse({ description: 'Scoped payment report page.', type: ReportPaymentPageResponseDto })
  @ApiBadRequestResponse({ description: 'Report query validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT and active branch are required.' })
  @ApiForbiddenResponse({ description: 'Tenant or branch authorization failed.' })
  @ApiInternalServerErrorResponse({ description: 'Report query failed unexpectedly.' })
  payments(
    @Req() request: ReportRequest,
    @Query() query: ReportListQueryDto,
  ): Promise<PaymentReportPage> {
    return this.reportService.payments(scope(request), query);
  }

  @Get('expenses')
  @ApiOperation({ summary: 'Get branch-scoped expenses and calculated expense metrics' })
  @ApiOkResponse({ description: 'Scoped expense report page.', type: ReportExpensePageResponseDto })
  @ApiBadRequestResponse({ description: 'Report query validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT and active branch are required.' })
  @ApiForbiddenResponse({ description: 'Tenant or branch authorization failed.' })
  @ApiInternalServerErrorResponse({ description: 'Report query failed unexpectedly.' })
  expenses(
    @Req() request: ReportRequest,
    @Query() query: ReportListQueryDto,
  ): Promise<ExpenseReportPage> {
    return this.reportService.expenses(scope(request), query);
  }
}
