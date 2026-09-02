import 'reflect-metadata';

import type { Connection } from 'mongoose';
import { Types } from 'mongoose';

import {
  createReportScopeFilter,
  MongoReportRepository,
} from '../src/report/report.mongo.repository';
import type { ReportPageQuery, ReportScope } from '../src/report/report.types';

const ACTOR_ID = '64f0c18f7c4d2f0012ab34bb';
const TENANT_A = '64f0c18f7c4d2f0012ab34aa';
const TENANT_B = '64f0c18f7c4d2f0012ab34cc';
const START = new Date('2026-08-01T00:00:00.000Z');
const END = new Date('2026-08-08T00:00:00.000Z');

function scope(tenantId = TENANT_A, branchId = 'branch-a'): ReportScope {
  return {
    actorId: ACTOR_ID,
    authorization: 'Bearer token',
    branchId,
    permissions: [],
    roleCode: 'tenant_owner',
    tenantId,
  };
}

const pageQuery: ReportPageQuery = {
  bucket: 'day',
  endDate: END,
  limit: 20,
  page: 1,
  startDate: START,
};

interface CapturedAggregation {
  readonly collection: string;
  readonly pipeline: readonly Record<string, unknown>[];
}

interface AggregateResult {
  readonly array?: readonly unknown[];
  readonly next?: unknown;
}

interface FakeAggregation {
  next(): Promise<unknown>;
  toArray(): Promise<readonly unknown[]>;
}

interface FakeCollection {
  aggregate(pipeline: readonly Record<string, unknown>[]): FakeAggregation;
}

function repositoryHarness(results: Readonly<Record<string, readonly AggregateResult[]>> = {}): {
  readonly captured: CapturedAggregation[];
  readonly repository: MongoReportRepository;
} {
  const captured: CapturedAggregation[] = [];
  const queues = Object.fromEntries(
    Object.entries(results).map(([collection, values]) => [collection, [...values]]),
  ) as Record<string, AggregateResult[]>;
  const connection = {
    collection: (collection: string): FakeCollection => ({
      aggregate: (pipeline: readonly Record<string, unknown>[]): FakeAggregation => {
        captured.push({ collection, pipeline });
        const result = queues[collection]?.shift() ?? {};
        return {
          next: (): Promise<unknown> => Promise.resolve(result.next ?? null),
          toArray: (): Promise<readonly unknown[]> => Promise.resolve(result.array ?? []),
        };
      },
    }),
  };
  return {
    captured,
    repository: new MongoReportRepository(connection as unknown as Connection),
  };
}

function firstMatch(call: CapturedAggregation): Record<string, unknown> {
  return (call.pipeline[0]?.$match ?? {}) as Record<string, unknown>;
}

describe('MongoReportRepository calculations and isolation', () => {
  it('constructs distinct, mandatory server-side branch and tenant filters', () => {
    expect(createReportScopeFilter(scope())).toEqual({
      branchId: 'branch-a',
      tenantId: expect.objectContaining({}) as unknown,
    });
    const branchB = createReportScopeFilter(scope(TENANT_A, 'branch-b'));
    const tenantB = createReportScopeFilter(scope(TENANT_B, 'branch-a'));
    expect(branchB.branchId).toBe('branch-b');
    expect(String(branchB.tenantId)).toBe(TENANT_A);
    expect(String(tenantB.tenantId)).toBe(TENANT_B);
  });

  it('returns every tenant branch from one tenant-scoped aggregation', async () => {
    const { captured, repository } = repositoryHarness({
      branches: [
        {
          array: [
            {
              branchCode: 'MAIN',
              branchId: 'branch-a',
              branchName: 'Main Branch',
              collected: 120,
              expenses: 30,
              netProfit: 170,
              orders: 4,
              outstanding: 80,
              revenue: 200,
              revenueSharePercentage: 80,
            },
            {
              branchId: 'branch-b',
              branchName: 'Branch 2',
              collected: 40,
              expenses: 10,
              netProfit: 40,
              orders: 2,
              outstanding: 10,
              revenue: 50,
              revenueSharePercentage: 20,
            },
          ],
        },
      ],
    });

    await expect(repository.branchPerformance(scope(), START, END)).resolves.toEqual({
      branches: [
        {
          branchCode: 'MAIN',
          branchId: 'branch-a',
          branchName: 'Main Branch',
          metrics: {
            collected: 120,
            expenses: 30,
            netProfit: 170,
            orders: 4,
            outstanding: 80,
            revenue: 200,
            revenueSharePercentage: 80,
          },
        },
        {
          branchId: 'branch-b',
          branchName: 'Branch 2',
          metrics: {
            collected: 40,
            expenses: 10,
            netProfit: 40,
            orders: 2,
            outstanding: 10,
            revenue: 50,
            revenueSharePercentage: 20,
          },
        },
      ],
    });

    expect(captured).toHaveLength(1);
    expect(captured[0].collection).toBe('branches');
    expect(firstMatch(captured[0])).toEqual({ tenantId: TENANT_A });
    expect(firstMatch(captured[0]).branchId).toBeUndefined();
    const serializedPipeline = JSON.stringify(captured[0].pipeline);
    expect(serializedPipeline).toContain(TENANT_A);
    expect(serializedPipeline).toContain('"isDeleted":false');
    expect(serializedPipeline).toContain('"from":"orders"');
    expect(serializedPipeline).toContain('"from":"payments"');
    expect(serializedPipeline).toContain('"from":"expenses"');
  });

  it('calculates order totals from the persisted order status values', async () => {
    const { repository } = repositoryHarness({
      orders: [
        {
          next: {
            items: [],
            statuses: [
              { _id: 'Delivered', count: 4, totalOrderValue: 400, totalOutstandingAmount: 0 },
              { _id: 'InProgress', count: 2, totalOrderValue: 180, totalOutstandingAmount: 80 },
              { _id: 'Ready', count: 1, totalOrderValue: 90, totalOutstandingAmount: 30 },
              { _id: 'Cancelled', count: 3, totalOrderValue: 210, totalOutstandingAmount: 210 },
            ],
            trend: [{ _id: START, orders: 3, revenue: 270 }],
          },
        },
      ],
    });

    await expect(repository.listOrders(scope(), pageQuery)).resolves.toMatchObject({
      metrics: {
        cancelledOrders: 3,
        completedOrders: 4,
        pendingOrders: 3,
        statusBreakdown: { Cancelled: 3, Delivered: 4, InProgress: 2, Ready: 1 },
        totalOrders: 10,
        totalOrderValue: 670,
        totalOutstandingAmount: 110,
        trend: [{ date: START, orders: 3, revenue: 270 }],
      },
      total: 10,
    });
  });

  it('calculates payment amounts and counts by persisted payment status', async () => {
    const { repository } = repositoryHarness({
      payments: [
        {
          next: {
            items: [],
            statuses: [
              { _id: 'Successful', amount: 25000, count: 5 },
              { _id: 'Pending', amount: 4000, count: 2 },
              { _id: 'Failed', amount: 1000, count: 1 },
            ],
            trend: [{ _id: START, amount: 15000, count: 3 }],
          },
        },
      ],
    });

    await expect(repository.listPayments(scope(), pageQuery)).resolves.toMatchObject({
      metrics: {
        collectedAmountMinor: 25000,
        failedAmountMinor: 1000,
        paymentCount: 8,
        pendingAmountMinor: 4000,
        statusBreakdown: { Failed: 1, Pending: 2, Successful: 5 },
        totalPaymentAmountMinor: 30000,
        trend: [{ amount: 15000, count: 3, date: START }],
      },
      total: 8,
    });
  });

  it('calculates active expense totals, categories, and trends', async () => {
    const categoryId = new Types.ObjectId();
    const { repository } = repositoryHarness({
      expenses: [
        {
          next: {
            categories: [
              {
                _id: { categoryId, categoryName: 'Utilities' },
                amount: 1200,
                count: 3,
              },
            ],
            items: [],
            totals: [{ count: 3, total: 1200 }],
            trend: [{ _id: START, amount: 500, count: 1 }],
          },
        },
      ],
    });

    await expect(repository.listExpenses(scope(), pageQuery)).resolves.toMatchObject({
      metrics: {
        categoryBreakdown: [
          { amount: 1200, categoryId: String(categoryId), categoryName: 'Utilities', count: 3 },
        ],
        expenseCount: 3,
        totalExpenses: 1200,
        trend: [{ amount: 500, count: 1, date: START }],
      },
      total: 3,
    });
  });

  it('returns zeroed metrics for an empty branch', async () => {
    const { repository } = repositoryHarness();
    await expect(repository.listOrders(scope(), pageQuery)).resolves.toMatchObject({
      items: [],
      metrics: {
        cancelledOrders: 0,
        completedOrders: 0,
        pendingOrders: 0,
        statusBreakdown: {},
        totalOrders: 0,
        totalOrderValue: 0,
        totalOutstandingAmount: 0,
        trend: [],
      },
      total: 0,
      totalPages: 0,
    });
  });

  it('scopes every aggregation and excludes soft-deleted expenses', async () => {
    const { captured, repository } = repositoryHarness();
    const selectedScope = scope();

    await repository.listOrders(selectedScope, pageQuery);
    await repository.listPayments(selectedScope, pageQuery);
    await repository.listExpenses(selectedScope, pageQuery);
    await repository.summaryFacts(
      selectedScope,
      START,
      END,
      new Date('2026-07-25T00:00:00.000Z'),
      'day',
    );

    expect(captured).toHaveLength(6);
    for (const call of captured) {
      const filter = firstMatch(call);
      expect(filter.branchId).toBe('branch-a');
      expect(String(filter.tenantId)).toBe(TENANT_A);
    }
    for (const call of captured.filter(({ collection }) => collection === 'expenses')) {
      expect(firstMatch(call).isDeleted).toBe(false);
    }
  });

  it('uses inclusive date boundaries and cannot mix another scope into them', async () => {
    const { captured, repository } = repositoryHarness();
    await repository.listOrders(scope(TENANT_B, 'branch-b'), pageQuery);
    const filter = firstMatch(captured[0]);

    expect(filter.branchId).toBe('branch-b');
    expect(String(filter.tenantId)).toBe(TENANT_B);
    expect(filter.createdAt).toEqual({ $gte: START, $lte: END });
  });
});
