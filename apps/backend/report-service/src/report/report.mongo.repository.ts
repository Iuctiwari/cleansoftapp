import { Injectable } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import type { Collection, Document, Filter, ObjectId, WithId } from 'mongodb';
import { Connection, Types } from 'mongoose';

import type {
  BranchPerformanceRecord,
  BranchPerformanceReport,
  ExpenseCategoryFact,
  ExpenseReportPage,
  OrderReportPage,
  PaymentReportPage,
  ReportAmountTrendFact,
  ReportExpenseRecord,
  ReportOrderRecord,
  ReportPageQuery,
  ReportPaymentRecord,
  ReportRepository,
  ReportScope,
  ReportServiceFact,
  ReportSummaryFacts,
  ReportTrendBucket,
  ReportTrendFact,
} from './report.types';

const CANCELLED_ORDER_STATUS = 'Cancelled';
const COMPLETED_ORDER_STATUS = 'Delivered';
const PENDING_ORDER_STATUSES = new Set([
  'Draft',
  'Received',
  'InProgress',
  'Ready',
  'OutForDelivery',
]);

interface OrderSource extends Document {
  readonly tenantId: ObjectId;
  readonly branchId: string;
  readonly orderNumber: string;
  readonly customerId: ObjectId;
  readonly customerSnapshot: Record<string, unknown>;
  readonly status: string;
  readonly paymentStatus: string;
  readonly items: readonly { readonly serviceSnapshot?: { readonly name?: string } }[];
  readonly subtotal: number;
  readonly discount: number;
  readonly tax: number;
  readonly grandTotal: number;
  readonly paidAmount: number;
  readonly outstandingAmount: number;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

interface PaymentSource extends Document {
  readonly tenantId: ObjectId;
  readonly branchId: string;
  readonly orderId: ObjectId;
  readonly customerId: ObjectId;
  readonly paymentNumber: string;
  readonly paymentType: string;
  readonly method: string;
  readonly amountMinor: number;
  readonly currency: string;
  readonly status: string;
  readonly recordedBy: ObjectId;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

interface ExpenseSource extends Document {
  readonly tenantId: ObjectId;
  readonly branchId: string;
  readonly expenseCategoryId: ObjectId;
  readonly amount: number;
  readonly paymentMethod: string;
  readonly vendor?: string;
  readonly description: string;
  readonly attachment?: string;
  readonly expenseDate: Date;
  readonly recordedBy: string;
  readonly isDeleted: boolean;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

interface BranchSource extends Document {
  readonly branchId: string;
  readonly branchName: string;
  readonly code?: string;
  readonly tenantId: string;
}

interface BranchPerformanceAggregation {
  readonly branchCode?: string;
  readonly branchId: string;
  readonly branchName: string;
  readonly collected: number;
  readonly expenses: number;
  readonly netProfit: number;
  readonly orders: number;
  readonly outstanding: number;
  readonly revenue: number;
  readonly revenueSharePercentage: number;
}

interface TotalAggregation {
  readonly count: number;
  readonly total: number;
}

interface TrendAggregation {
  readonly _id: Date;
  readonly orders: number;
  readonly revenue: number;
}

interface AmountTrendAggregation {
  readonly _id: Date;
  readonly amount: number;
  readonly count: number;
}

interface ServiceAggregation {
  readonly _id: string;
  readonly count: number;
}

interface OrderStatusAggregation {
  readonly _id: string;
  readonly count: number;
  readonly totalOrderValue: number;
  readonly totalOutstandingAmount: number;
}

interface PaymentStatusAggregation {
  readonly _id: string;
  readonly amount: number;
  readonly count: number;
}

interface ExpenseCategoryAggregation {
  readonly _id: { readonly categoryId: ObjectId; readonly categoryName?: string | null };
  readonly amount: number;
  readonly count: number;
}

interface OrderPageAggregation {
  readonly items: readonly WithId<OrderSource>[];
  readonly statuses: readonly OrderStatusAggregation[];
  readonly trend: readonly TrendAggregation[];
}

interface PaymentPageAggregation {
  readonly items: readonly WithId<PaymentSource>[];
  readonly statuses: readonly PaymentStatusAggregation[];
  readonly trend: readonly AmountTrendAggregation[];
}

interface ExpensePageAggregation {
  readonly categories: readonly ExpenseCategoryAggregation[];
  readonly items: readonly WithId<ExpenseSource>[];
  readonly totals: readonly TotalAggregation[];
  readonly trend: readonly AmountTrendAggregation[];
}

interface SummaryOrderAggregation {
  readonly current: readonly TotalAggregation[];
  readonly previous: readonly TotalAggregation[];
  readonly services: readonly ServiceAggregation[];
  readonly trend: readonly TrendAggregation[];
}

export function createReportScopeFilter(scope: ReportScope): {
  readonly branchId: string;
  readonly tenantId: Types.ObjectId;
} {
  return {
    branchId: scope.branchId,
    tenantId: new Types.ObjectId(scope.tenantId),
  };
}

@Injectable()
export class MongoReportRepository implements ReportRepository {
  private readonly branches: Collection<BranchSource>;
  private readonly expenses: Collection<ExpenseSource>;
  private readonly orders: Collection<OrderSource>;
  private readonly payments: Collection<PaymentSource>;

  constructor(@InjectConnection() connection: Connection) {
    this.branches = connection.collection<BranchSource>('branches');
    this.expenses = connection.collection<ExpenseSource>('expenses');
    this.orders = connection.collection<OrderSource>('orders');
    this.payments = connection.collection<PaymentSource>('payments');
  }

  async branchPerformance(
    scope: ReportScope,
    startDate: Date,
    endDate: Date,
  ): Promise<BranchPerformanceReport> {
    const tenantObjectId = new Types.ObjectId(scope.tenantId);
    const values = await this.branches
      .aggregate<BranchPerformanceAggregation>([
        { $match: { tenantId: scope.tenantId } },
        {
          $lookup: {
            as: 'orderMetrics',
            from: 'orders',
            let: { selectedBranchId: '$branchId' },
            pipeline: [
              {
                $match: {
                  createdAt: { $gte: startDate, $lte: endDate },
                  tenantId: tenantObjectId,
                  $expr: { $eq: ['$branchId', '$$selectedBranchId'] },
                },
              },
              {
                $group: {
                  _id: null,
                  orders: { $sum: 1 },
                  outstanding: {
                    $sum: {
                      $cond: [
                        { $ne: ['$status', CANCELLED_ORDER_STATUS] },
                        '$outstandingAmount',
                        0,
                      ],
                    },
                  },
                  revenue: {
                    $sum: {
                      $cond: [{ $ne: ['$status', CANCELLED_ORDER_STATUS] }, '$grandTotal', 0],
                    },
                  },
                },
              },
            ],
          },
        },
        {
          $lookup: {
            as: 'paymentMetrics',
            from: 'payments',
            let: { selectedBranchId: '$branchId' },
            pipeline: [
              {
                $match: {
                  createdAt: { $gte: startDate, $lte: endDate },
                  status: 'Successful',
                  tenantId: tenantObjectId,
                  $expr: { $eq: ['$branchId', '$$selectedBranchId'] },
                },
              },
              { $group: { _id: null, collectedMinor: { $sum: '$amountMinor' } } },
            ],
          },
        },
        {
          $lookup: {
            as: 'expenseMetrics',
            from: 'expenses',
            let: { selectedBranchId: '$branchId' },
            pipeline: [
              {
                $match: {
                  expenseDate: { $gte: startDate, $lte: endDate },
                  isDeleted: false,
                  tenantId: tenantObjectId,
                  $expr: { $eq: ['$branchId', '$$selectedBranchId'] },
                },
              },
              { $group: { _id: null, expenses: { $sum: '$amount' } } },
            ],
          },
        },
        {
          $set: {
            expenseMetrics: {
              $ifNull: [{ $arrayElemAt: ['$expenseMetrics', 0] }, { expenses: 0 }],
            },
            orderMetrics: {
              $ifNull: [
                { $arrayElemAt: ['$orderMetrics', 0] },
                { orders: 0, outstanding: 0, revenue: 0 },
              ],
            },
            paymentMetrics: {
              $ifNull: [{ $arrayElemAt: ['$paymentMetrics', 0] }, { collectedMinor: 0 }],
            },
          },
        },
        {
          $project: {
            _id: 0,
            branchCode: '$code',
            branchId: 1,
            branchName: 1,
            collected: { $divide: ['$paymentMetrics.collectedMinor', 100] },
            expenses: '$expenseMetrics.expenses',
            netProfit: { $subtract: ['$orderMetrics.revenue', '$expenseMetrics.expenses'] },
            orders: '$orderMetrics.orders',
            outstanding: '$orderMetrics.outstanding',
            revenue: '$orderMetrics.revenue',
          },
        },
        {
          $setWindowFields: {
            output: {
              tenantRevenue: {
                $sum: '$revenue',
                window: { documents: ['unbounded', 'unbounded'] },
              },
            },
          },
        },
        {
          $set: {
            revenueSharePercentage: {
              $cond: [
                { $eq: ['$tenantRevenue', 0] },
                0,
                { $round: [{ $multiply: [{ $divide: ['$revenue', '$tenantRevenue'] }, 100] }, 2] },
              ],
            },
          },
        },
        { $unset: 'tenantRevenue' },
        { $sort: { branchName: 1, branchId: 1 } },
      ])
      .toArray();

    return {
      branches: values.map<BranchPerformanceRecord>((value) => ({
        ...(value.branchCode ? { branchCode: value.branchCode } : {}),
        branchId: value.branchId,
        branchName: value.branchName,
        metrics: {
          collected: value.collected,
          expenses: value.expenses,
          netProfit: value.netProfit,
          orders: value.orders,
          outstanding: value.outstanding,
          revenue: value.revenue,
          revenueSharePercentage: value.revenueSharePercentage,
        },
      })),
    };
  }

  async listOrders(scope: ReportScope, query: ReportPageQuery): Promise<OrderReportPage> {
    const filter: Filter<OrderSource> = {
      ...createReportScopeFilter(scope),
      ...this.dateFilter('createdAt', query),
    };
    const skip = (query.page - 1) * query.limit;
    const result = await this.orders
      .aggregate<OrderPageAggregation>([
        { $match: filter },
        {
          $facet: {
            items: [
              { $sort: { createdAt: -1, _id: -1 } },
              { $skip: skip },
              { $limit: query.limit },
            ],
            statuses: [
              {
                $group: {
                  _id: '$status',
                  count: { $sum: 1 },
                  totalOrderValue: { $sum: '$grandTotal' },
                  totalOutstandingAmount: { $sum: '$outstandingAmount' },
                },
              },
              { $sort: { _id: 1 } },
            ],
            trend: [
              {
                $group: {
                  _id: { $dateTrunc: { date: '$createdAt', unit: query.bucket } },
                  orders: { $sum: 1 },
                  revenue: {
                    $sum: {
                      $cond: [{ $ne: ['$status', CANCELLED_ORDER_STATUS] }, '$grandTotal', 0],
                    },
                  },
                },
              },
              { $sort: { _id: 1 } },
            ],
          },
        },
      ])
      .next();
    const statuses = result?.statuses ?? [];
    const total = statuses.reduce((sum, item) => sum + item.count, 0);

    return {
      items: (result?.items ?? []).map((document) => this.mapOrder(document)),
      limit: query.limit,
      metrics: {
        cancelledOrders: this.statusCount(statuses, (status) => status === CANCELLED_ORDER_STATUS),
        completedOrders: this.statusCount(statuses, (status) => status === COMPLETED_ORDER_STATUS),
        pendingOrders: this.statusCount(statuses, (status) => PENDING_ORDER_STATUSES.has(status)),
        statusBreakdown: this.statusBreakdown(statuses),
        totalOrderValue: statuses
          .filter((item) => item._id !== CANCELLED_ORDER_STATUS)
          .reduce((sum, item) => sum + item.totalOrderValue, 0),
        totalOrders: total,
        totalOutstandingAmount: statuses
          .filter((item) => item._id !== CANCELLED_ORDER_STATUS)
          .reduce((sum, item) => sum + item.totalOutstandingAmount, 0),
        trend: this.orderTrend(result?.trend ?? []),
      },
      page: query.page,
      total,
      totalPages: Math.ceil(total / query.limit),
    };
  }

  async listPayments(scope: ReportScope, query: ReportPageQuery): Promise<PaymentReportPage> {
    const filter: Filter<PaymentSource> = {
      ...createReportScopeFilter(scope),
      ...this.dateFilter('createdAt', query),
    };
    const skip = (query.page - 1) * query.limit;
    const result = await this.payments
      .aggregate<PaymentPageAggregation>([
        { $match: filter },
        {
          $facet: {
            items: [
              { $sort: { createdAt: -1, _id: -1 } },
              { $skip: skip },
              { $limit: query.limit },
            ],
            statuses: [
              {
                $group: {
                  _id: '$status',
                  amount: { $sum: '$amountMinor' },
                  count: { $sum: 1 },
                },
              },
              { $sort: { _id: 1 } },
            ],
            trend: [
              {
                $group: {
                  _id: { $dateTrunc: { date: '$createdAt', unit: query.bucket } },
                  amount: { $sum: '$amountMinor' },
                  count: { $sum: 1 },
                },
              },
              { $sort: { _id: 1 } },
            ],
          },
        },
      ])
      .next();
    const statuses = result?.statuses ?? [];
    const total = statuses.reduce((sum, item) => sum + item.count, 0);

    return {
      items: (result?.items ?? []).map((document) => this.mapPayment(document)),
      limit: query.limit,
      metrics: {
        collectedAmountMinor: this.paymentAmount(statuses, 'Successful'),
        failedAmountMinor: this.paymentAmount(statuses, 'Failed'),
        paymentCount: total,
        pendingAmountMinor: this.paymentAmount(statuses, 'Pending'),
        statusBreakdown: this.statusBreakdown(statuses),
        totalPaymentAmountMinor: statuses.reduce((sum, item) => sum + item.amount, 0),
        trend: this.amountTrend(result?.trend ?? []),
      },
      page: query.page,
      total,
      totalPages: Math.ceil(total / query.limit),
    };
  }

  async listExpenses(scope: ReportScope, query: ReportPageQuery): Promise<ExpenseReportPage> {
    const filter: Filter<ExpenseSource> = {
      ...createReportScopeFilter(scope),
      isDeleted: false,
      ...this.dateFilter('expenseDate', query),
    };
    const skip = (query.page - 1) * query.limit;
    const result = await this.expenses
      .aggregate<ExpensePageAggregation>([
        { $match: filter },
        {
          $facet: {
            categories: [
              {
                $lookup: {
                  as: 'category',
                  from: 'expenseCategories',
                  let: { categoryId: '$expenseCategoryId', tenantId: '$tenantId' },
                  pipeline: [
                    {
                      $match: {
                        $expr: {
                          $and: [
                            { $eq: ['$_id', '$$categoryId'] },
                            { $eq: ['$tenantId', '$$tenantId'] },
                          ],
                        },
                      },
                    },
                    { $project: { categoryName: 1 } },
                  ],
                },
              },
              { $set: { categoryName: { $arrayElemAt: ['$category.categoryName', 0] } } },
              {
                $group: {
                  _id: { categoryId: '$expenseCategoryId', categoryName: '$categoryName' },
                  amount: { $sum: '$amount' },
                  count: { $sum: 1 },
                },
              },
              { $sort: { amount: -1, '_id.categoryId': 1 } },
            ],
            items: [
              { $sort: { expenseDate: -1, _id: -1 } },
              { $skip: skip },
              { $limit: query.limit },
            ],
            totals: [{ $group: { _id: null, count: { $sum: 1 }, total: { $sum: '$amount' } } }],
            trend: [
              {
                $group: {
                  _id: { $dateTrunc: { date: '$expenseDate', unit: query.bucket } },
                  amount: { $sum: '$amount' },
                  count: { $sum: 1 },
                },
              },
              { $sort: { _id: 1 } },
            ],
          },
        },
      ])
      .next();
    const totals = result?.totals[0] ?? { count: 0, total: 0 };

    return {
      items: (result?.items ?? []).map((document) => this.mapExpense(document)),
      limit: query.limit,
      metrics: {
        categoryBreakdown: (result?.categories ?? []).map<ExpenseCategoryFact>((item) => ({
          amount: item.amount,
          categoryId: String(item._id.categoryId),
          ...(item._id.categoryName ? { categoryName: item._id.categoryName } : {}),
          count: item.count,
        })),
        expenseCount: totals.count,
        totalExpenses: totals.total,
        trend: this.amountTrend(result?.trend ?? []),
      },
      page: query.page,
      total: totals.count,
      totalPages: Math.ceil(totals.count / query.limit),
    };
  }

  async summaryFacts(
    scope: ReportScope,
    startDate: Date,
    endDate: Date,
    previousStartDate: Date,
    bucket: ReportTrendBucket,
  ): Promise<ReportSummaryFacts> {
    const scoped = createReportScopeFilter(scope);
    const orderResultPromise = this.orders
      .aggregate<SummaryOrderAggregation>([
        {
          $match: {
            ...scoped,
            createdAt: { $gte: previousStartDate, $lte: endDate },
          },
        },
        {
          $facet: {
            current: [
              { $match: { createdAt: { $gte: startDate, $lte: endDate } } },
              {
                $group: {
                  _id: null,
                  count: { $sum: 1 },
                  total: {
                    $sum: {
                      $cond: [{ $ne: ['$status', CANCELLED_ORDER_STATUS] }, '$grandTotal', 0],
                    },
                  },
                },
              },
            ],
            previous: [
              { $match: { createdAt: { $gte: previousStartDate, $lt: startDate } } },
              {
                $group: {
                  _id: null,
                  count: { $sum: 1 },
                  total: {
                    $sum: {
                      $cond: [{ $ne: ['$status', CANCELLED_ORDER_STATUS] }, '$grandTotal', 0],
                    },
                  },
                },
              },
            ],
            services: [
              {
                $match: {
                  createdAt: { $gte: startDate, $lte: endDate },
                  status: { $ne: CANCELLED_ORDER_STATUS },
                },
              },
              { $unwind: '$items' },
              { $match: { 'items.serviceSnapshot.name': { $type: 'string' } } },
              { $group: { _id: '$items.serviceSnapshot.name', count: { $sum: 1 } } },
              { $sort: { count: -1, _id: 1 } },
            ],
            trend: [
              { $match: { createdAt: { $gte: startDate, $lte: endDate } } },
              {
                $group: {
                  _id: { $dateTrunc: { date: '$createdAt', unit: bucket } },
                  orders: { $sum: 1 },
                  revenue: {
                    $sum: {
                      $cond: [{ $ne: ['$status', CANCELLED_ORDER_STATUS] }, '$grandTotal', 0],
                    },
                  },
                },
              },
              { $sort: { _id: 1 } },
            ],
          },
        },
      ])
      .next();
    const paymentResultPromise = this.total(
      this.payments,
      { ...scoped, createdAt: { $gte: startDate, $lte: endDate }, status: 'Successful' },
      '$amountMinor',
    );
    const expenseResultPromise = this.total(
      this.expenses,
      { ...scoped, expenseDate: { $gte: startDate, $lte: endDate }, isDeleted: false },
      '$amount',
    );
    const [orderResult, payments, expenses] = await Promise.all([
      orderResultPromise,
      paymentResultPromise,
      expenseResultPromise,
    ]);
    const current = orderResult?.current[0] ?? { count: 0, total: 0 };
    const previous = orderResult?.previous[0] ?? { count: 0, total: 0 };

    return {
      collectedMinor: payments.total,
      expenses: expenses.total,
      orderCount: current.count,
      previousOrderCount: previous.count,
      previousRevenue: previous.total,
      revenue: current.total,
      services: (orderResult?.services ?? []).map<ReportServiceFact>((item) => ({
        count: item.count,
        name: item._id,
      })),
      trend: this.orderTrend(orderResult?.trend ?? []),
    };
  }

  private dateFilter(
    field: 'createdAt' | 'expenseDate',
    query: ReportPageQuery,
  ): Record<string, { readonly $gte?: Date; readonly $lte?: Date }> {
    if (!query.startDate && !query.endDate) return {};
    return {
      [field]: {
        ...(query.startDate ? { $gte: query.startDate } : {}),
        ...(query.endDate ? { $lte: query.endDate } : {}),
      },
    };
  }

  private mapOrder(document: WithId<OrderSource>): ReportOrderRecord {
    return {
      branchId: document.branchId,
      createdAt: document.createdAt,
      customerId: String(document.customerId),
      customerSnapshot: document.customerSnapshot,
      discount: document.discount,
      grandTotal: document.grandTotal,
      id: String(document._id),
      orderNumber: document.orderNumber,
      outstandingAmount: document.outstandingAmount,
      paidAmount: document.paidAmount,
      paymentStatus: document.paymentStatus,
      status: document.status,
      subtotal: document.subtotal,
      tax: document.tax,
      updatedAt: document.updatedAt,
    };
  }

  private mapPayment(document: WithId<PaymentSource>): ReportPaymentRecord {
    return {
      amountMinor: document.amountMinor,
      branchId: document.branchId,
      createdAt: document.createdAt,
      currency: document.currency,
      customerId: String(document.customerId),
      id: String(document._id),
      method: document.method,
      orderId: String(document.orderId),
      paymentNumber: document.paymentNumber,
      paymentType: document.paymentType,
      recordedBy: String(document.recordedBy),
      status: document.status,
      updatedAt: document.updatedAt,
    };
  }

  private mapExpense(document: WithId<ExpenseSource>): ReportExpenseRecord {
    return {
      amount: document.amount,
      attachment: document.attachment,
      branchId: document.branchId,
      createdAt: document.createdAt,
      description: document.description,
      expenseCategoryId: String(document.expenseCategoryId),
      expenseDate: document.expenseDate,
      id: String(document._id),
      paymentMethod: document.paymentMethod,
      recordedBy: document.recordedBy,
      updatedAt: document.updatedAt,
      vendor: document.vendor,
    };
  }

  private orderTrend(items: readonly TrendAggregation[]): ReportTrendFact[] {
    return items.map((item) => ({
      date: item._id,
      orders: item.orders,
      revenue: item.revenue,
    }));
  }

  private amountTrend(items: readonly AmountTrendAggregation[]): ReportAmountTrendFact[] {
    return items.map((item) => ({ amount: item.amount, count: item.count, date: item._id }));
  }

  private statusBreakdown(items: readonly { readonly _id: string; readonly count: number }[]): {
    readonly [status: string]: number;
  } {
    return Object.fromEntries(items.map((item) => [item._id, item.count]));
  }

  private statusCount(
    items: readonly OrderStatusAggregation[],
    predicate: (status: string) => boolean,
  ): number {
    return items.filter((item) => predicate(item._id)).reduce((sum, item) => sum + item.count, 0);
  }

  private paymentAmount(items: readonly PaymentStatusAggregation[], status: string): number {
    return items.find((item) => item._id === status)?.amount ?? 0;
  }

  private async total<TSource extends Document>(
    collection: Collection<TSource>,
    filter: Filter<TSource>,
    amountExpression: string,
  ): Promise<TotalAggregation> {
    const values = await collection
      .aggregate<TotalAggregation>([
        { $match: filter },
        { $group: { _id: null, count: { $sum: 1 }, total: { $sum: amountExpression } } },
      ])
      .toArray();
    return values[0] ?? { count: 0, total: 0 };
  }
}
