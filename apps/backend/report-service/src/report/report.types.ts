export const REPORT_REPOSITORY = Symbol('REPORT_REPOSITORY');

export interface ReportScope {
  readonly actorId: string;
  readonly authorization: string;
  readonly branchId: string;
  readonly permissions: readonly string[];
  readonly roleCode: string;
  readonly tenantId: string;
}

export interface ReportPageQuery {
  readonly bucket: ReportTrendBucket;
  readonly endDate?: Date;
  readonly limit: number;
  readonly page: number;
  readonly startDate?: Date;
}

export type ReportTrendBucket = 'day' | 'week' | 'month';

export interface ReportPage<TItem> {
  readonly items: readonly TItem[];
  readonly limit: number;
  readonly page: number;
  readonly total: number;
  readonly totalPages: number;
}

export interface ReportOrderRecord {
  readonly id: string;
  readonly branchId: string;
  readonly orderNumber: string;
  readonly customerId: string;
  readonly customerSnapshot: Record<string, unknown>;
  readonly status: string;
  readonly paymentStatus: string;
  readonly subtotal: number;
  readonly discount: number;
  readonly tax: number;
  readonly grandTotal: number;
  readonly paidAmount: number;
  readonly outstandingAmount: number;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface ReportPaymentRecord {
  readonly id: string;
  readonly branchId: string;
  readonly orderId: string;
  readonly customerId: string;
  readonly paymentNumber: string;
  readonly paymentType: string;
  readonly method: string;
  readonly amountMinor: number;
  readonly currency: string;
  readonly status: string;
  readonly recordedBy: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface ReportExpenseRecord {
  readonly id: string;
  readonly branchId: string;
  readonly expenseCategoryId: string;
  readonly amount: number;
  readonly paymentMethod: string;
  readonly vendor?: string;
  readonly description: string;
  readonly attachment?: string;
  readonly expenseDate: Date;
  readonly recordedBy: string;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export interface ReportTrendFact {
  readonly date: Date;
  readonly orders: number;
  readonly revenue: number;
}

export interface ReportAmountTrendFact {
  readonly amount: number;
  readonly count: number;
  readonly date: Date;
}

export interface ReportStatusFact {
  readonly amount: number;
  readonly count: number;
  readonly status: string;
}

export interface OrderReportMetrics {
  readonly cancelledOrders: number;
  readonly completedOrders: number;
  readonly pendingOrders: number;
  readonly statusBreakdown: Readonly<Record<string, number>>;
  readonly totalOrderValue: number;
  readonly totalOrders: number;
  readonly totalOutstandingAmount: number;
  readonly trend: readonly ReportTrendFact[];
}

export interface PaymentReportMetrics {
  readonly collectedAmountMinor: number;
  readonly failedAmountMinor: number;
  readonly paymentCount: number;
  readonly pendingAmountMinor: number;
  readonly statusBreakdown: Readonly<Record<string, number>>;
  readonly totalPaymentAmountMinor: number;
  readonly trend: readonly ReportAmountTrendFact[];
}

export interface ExpenseCategoryFact {
  readonly amount: number;
  readonly categoryId: string;
  readonly categoryName?: string;
  readonly count: number;
}

export interface ExpenseReportMetrics {
  readonly categoryBreakdown: readonly ExpenseCategoryFact[];
  readonly expenseCount: number;
  readonly totalExpenses: number;
  readonly trend: readonly ReportAmountTrendFact[];
}

export interface OrderReportPage extends ReportPage<ReportOrderRecord> {
  readonly metrics: OrderReportMetrics;
}

export interface PaymentReportPage extends ReportPage<ReportPaymentRecord> {
  readonly metrics: PaymentReportMetrics;
}

export interface ExpenseReportPage extends ReportPage<ReportExpenseRecord> {
  readonly metrics: ExpenseReportMetrics;
}

export interface BranchPerformanceMetrics {
  readonly collected: number;
  readonly expenses: number;
  readonly netProfit: number;
  readonly orders: number;
  readonly outstanding: number;
  readonly revenue: number;
  readonly revenueSharePercentage: number;
}

export interface BranchPerformanceRecord {
  readonly branchCode?: string;
  readonly branchId: string;
  readonly branchName: string;
  readonly metrics: BranchPerformanceMetrics;
}

export interface BranchPerformanceReport {
  readonly branches: readonly BranchPerformanceRecord[];
}

export interface ReportServiceFact {
  readonly name: string;
  readonly count: number;
}

export interface ReportSummaryFacts {
  readonly collectedMinor: number;
  readonly expenses: number;
  readonly orderCount: number;
  readonly previousOrderCount: number;
  readonly previousRevenue: number;
  readonly revenue: number;
  readonly services: readonly ReportServiceFact[];
  readonly trend: readonly ReportTrendFact[];
}

export interface ReportRepository {
  branchPerformance(
    scope: ReportScope,
    startDate: Date,
    endDate: Date,
  ): Promise<BranchPerformanceReport>;
  listExpenses(scope: ReportScope, query: ReportPageQuery): Promise<ExpenseReportPage>;
  listOrders(scope: ReportScope, query: ReportPageQuery): Promise<OrderReportPage>;
  listPayments(scope: ReportScope, query: ReportPageQuery): Promise<PaymentReportPage>;
  summaryFacts(
    scope: ReportScope,
    startDate: Date,
    endDate: Date,
    previousStartDate: Date,
    bucket: ReportTrendBucket,
  ): Promise<ReportSummaryFacts>;
}
