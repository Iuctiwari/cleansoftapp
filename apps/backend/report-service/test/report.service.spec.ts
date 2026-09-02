import { ReportPeriod } from '../src/report/report.dto';
import { ReportService } from '../src/report/report.service';
import type { ReportRepository, ReportScope, ReportSummaryFacts } from '../src/report/report.types';

const facts: ReportSummaryFacts = {
  collectedMinor: 940000,
  expenses: 2500,
  orderCount: 12,
  previousOrderCount: 10,
  previousRevenue: 8000,
  revenue: 10000,
  services: [
    { count: 3, name: 'Wash & Fold' },
    { count: 1, name: 'Dry Cleaning' },
  ],
  trend: [{ date: new Date('2026-08-24T00:00:00.000Z'), orders: 12, revenue: 10000 }],
};

const scope: ReportScope = {
  actorId: '64f0c18f7c4d2f0012ab34bb',
  authorization: 'Bearer token',
  branchId: 'branch-a',
  permissions: [],
  roleCode: 'tenant_owner',
  tenantId: '64f0c18f7c4d2f0012ab34aa',
};

describe('ReportService', () => {
  let branchPerformanceMock: jest.MockedFunction<ReportRepository['branchPerformance']>;
  let listOrdersMock: jest.MockedFunction<ReportRepository['listOrders']>;
  let repository: ReportRepository;
  let service: ReportService;
  let summaryFactsMock: jest.MockedFunction<ReportRepository['summaryFacts']>;

  beforeEach(() => {
    branchPerformanceMock = jest.fn();
    listOrdersMock = jest.fn();
    summaryFactsMock = jest.fn().mockResolvedValue(facts);
    repository = {
      branchPerformance: branchPerformanceMock,
      listExpenses: jest.fn(),
      listOrders: listOrdersMock,
      listPayments: jest.fn(),
      summaryFacts: summaryFactsMock,
    };
    service = new ReportService(repository);
  });

  afterEach(() => jest.useRealTimers());

  it('maps real source facts to the existing Report UI contract', async () => {
    await expect(service.summary(scope, { period: ReportPeriod.SEVEN_DAYS })).resolves.toEqual({
      collected: 9400,
      collectionRate: 94,
      netProfit: 7500,
      orderChange: 2,
      revenueChange: 25,
      serviceBreakdown: [
        { name: 'Wash & Fold', percentage: 75 },
        { name: 'Dry Cleaning', percentage: 25 },
      ],
      totalOrders: 12,
      totalRevenue: 10000,
      trend: [{ label: 'Mon', orders: 12, revenue: 10000 }],
    });
  });

  it('allows only the tenant owner to load all-branch performance', async () => {
    branchPerformanceMock.mockResolvedValue({ branches: [] });

    await expect(
      service.branchPerformance(scope, { period: ReportPeriod.SEVEN_DAYS }),
    ).resolves.toEqual({ branches: [] });
    expect(branchPerformanceMock).toHaveBeenCalledWith(scope, expect.any(Date), expect.any(Date));

    await expect(
      service.branchPerformance(
        { ...scope, roleCode: 'branch_manager' },
        { period: ReportPeriod.SEVEN_DAYS },
      ),
    ).rejects.toThrow('Tenant owner access is required');
  });

  it('uses the equivalent immediately preceding custom period', async () => {
    await service.summary(scope, {
      endDate: '2026-08-08T00:00:00.000Z',
      period: ReportPeriod.SEVEN_DAYS,
      startDate: '2026-08-01T00:00:00.000Z',
    });

    expect(summaryFactsMock).toHaveBeenCalledWith(
      scope,
      new Date('2026-08-01T00:00:00.000Z'),
      new Date('2026-08-08T00:00:00.000Z'),
      new Date('2026-07-25T00:00:00.000Z'),
      'day',
    );
  });

  it.each([
    { current: 0, expected: 0 },
    { current: 500, expected: 100 },
  ])('handles a zero previous-period revenue safely', async ({ current, expected }) => {
    summaryFactsMock.mockResolvedValue({
      ...facts,
      previousOrderCount: 0,
      previousRevenue: 0,
      revenue: current,
    });

    const result = await service.summary(scope, { period: ReportPeriod.SEVEN_DAYS });
    expect(result.revenueChange).toBe(expected);
    expect(Number.isFinite(result.revenueChange)).toBe(true);
  });

  it('applies a preset range to list reports before repository aggregation', async () => {
    jest.useFakeTimers().setSystemTime(new Date('2026-08-25T12:00:00.000Z'));
    listOrdersMock.mockResolvedValue({
      items: [],
      limit: 20,
      metrics: {
        cancelledOrders: 0,
        completedOrders: 0,
        pendingOrders: 0,
        statusBreakdown: {},
        totalOrderValue: 0,
        totalOrders: 0,
        totalOutstandingAmount: 0,
        trend: [],
      },
      page: 1,
      total: 0,
      totalPages: 0,
    });

    await service.orders(scope, { limit: 20, page: 1, period: ReportPeriod.THIRTY_DAYS });

    expect(listOrdersMock).toHaveBeenCalledWith(scope, {
      bucket: 'day',
      endDate: new Date('2026-08-25T12:00:00.000Z'),
      limit: 20,
      page: 1,
      startDate: new Date('2026-07-26T12:00:00.000Z'),
    });
  });

  it('rejects an inverted list date range before querying MongoDB', () => {
    expect(() =>
      service.orders(scope, {
        endDate: '2026-08-01T00:00:00.000Z',
        limit: 20,
        page: 1,
        startDate: '2026-08-02T00:00:00.000Z',
      }),
    ).toThrow('startDate must not be after endDate');
    expect(listOrdersMock).not.toHaveBeenCalled();
  });

  it('requires both custom summary boundaries', async () => {
    await expect(
      service.summary(scope, {
        period: ReportPeriod.SEVEN_DAYS,
        startDate: '2026-08-01T00:00:00.000Z',
      }),
    ).rejects.toThrow('startDate and endDate must be supplied together');
    expect(summaryFactsMock).not.toHaveBeenCalled();
  });
});
