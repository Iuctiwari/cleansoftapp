import { BadRequestException, ForbiddenException, Inject, Injectable } from '@nestjs/common';
import { Permissions, hasPermission, isBranchManagerRole, isOwnerRole } from '@nexoraa/shared';

import { ReportListQueryDto, ReportPeriod, ReportSummaryQueryDto } from './report.dto';
import {
  REPORT_REPOSITORY,
  type BranchPerformanceReport,
  type ExpenseReportPage,
  type OrderReportPage,
  type ReportPageQuery,
  type PaymentReportPage,
  type ReportRepository,
  type ReportScope,
  type ReportTrendBucket,
} from './report.types';

export interface ReportSummary {
  readonly collected: number;
  readonly collectionRate: number;
  readonly netProfit: number;
  readonly orderChange: number;
  readonly serviceBreakdown: readonly { readonly name: string; readonly percentage: number }[];
  readonly totalOrders: number;
  readonly totalRevenue: number;
  readonly revenueChange: number;
  readonly trend: readonly {
    readonly label: string;
    readonly orders: number;
    readonly revenue: number;
  }[];
}

interface PeriodRange {
  readonly bucket: ReportTrendBucket;
  readonly endDate: Date;
  readonly previousStartDate: Date;
  readonly startDate: Date;
}

@Injectable()
export class ReportService {
  constructor(@Inject(REPORT_REPOSITORY) private readonly repository: ReportRepository) {}

  async summary(scope: ReportScope, query: ReportSummaryQueryDto): Promise<ReportSummary> {
    this.assertRead(scope);
    const range = this.summaryRange(query);
    const facts = await this.repository.summaryFacts(
      scope,
      range.startDate,
      range.endDate,
      range.previousStartDate,
      range.bucket,
    );
    const collected = this.round(facts.collectedMinor / 100);
    const serviceTotal = facts.services.reduce((sum, service) => sum + service.count, 0);

    return {
      collected,
      collectionRate: facts.revenue === 0 ? 0 : this.round((collected / facts.revenue) * 100),
      netProfit: this.round(facts.revenue - facts.expenses),
      orderChange: facts.orderCount - facts.previousOrderCount,
      serviceBreakdown: facts.services.map((service) => ({
        name: service.name,
        percentage: serviceTotal === 0 ? 0 : Math.round((service.count / serviceTotal) * 100),
      })),
      totalOrders: facts.orderCount,
      totalRevenue: this.round(facts.revenue),
      revenueChange:
        facts.previousRevenue === 0
          ? facts.revenue === 0
            ? 0
            : 100
          : this.round(((facts.revenue - facts.previousRevenue) / facts.previousRevenue) * 100),
      trend: facts.trend.map((point) => ({
        label: this.label(point.date, range),
        orders: point.orders,
        revenue: this.round(point.revenue),
      })),
    };
  }

  async branchPerformance(
    scope: ReportScope,
    query: ReportSummaryQueryDto,
  ): Promise<BranchPerformanceReport> {
    if (!isOwnerRole(scope.roleCode)) {
      throw new ForbiddenException('Tenant owner access is required for branch performance');
    }
    const range = this.summaryRange(query);
    return this.repository.branchPerformance(scope, range.startDate, range.endDate);
  }

  orders(scope: ReportScope, query: ReportListQueryDto): Promise<OrderReportPage> {
    this.assertRead(scope);
    return this.repository.listOrders(scope, this.pageQuery(query));
  }

  payments(scope: ReportScope, query: ReportListQueryDto): Promise<PaymentReportPage> {
    this.assertRead(scope);
    return this.repository.listPayments(scope, this.pageQuery(query));
  }

  expenses(scope: ReportScope, query: ReportListQueryDto): Promise<ExpenseReportPage> {
    this.assertRead(scope);
    return this.repository.listExpenses(scope, this.pageQuery(query));
  }

  private assertRead(scope: ReportScope): void {
    if (
      !(isOwnerRole(scope.roleCode) || isBranchManagerRole(scope.roleCode)) ||
      !hasPermission(scope.roleCode, scope.permissions, Permissions.reportsRead)
    ) {
      throw new ForbiddenException('Report read permission is required');
    }
  }

  private pageQuery(query: ReportListQueryDto): ReportPageQuery {
    let startDate = query.startDate ? new Date(query.startDate) : undefined;
    let endDate = query.endDate ? new Date(query.endDate) : undefined;
    if (startDate && endDate && startDate > endDate) {
      throw new BadRequestException('startDate must not be after endDate');
    }
    if (!startDate && !endDate && query.period) {
      const preset = this.presetRange(query.period);
      startDate = preset.startDate;
      endDate = preset.endDate;
    }
    return {
      bucket: this.bucketForRange(startDate, endDate),
      endDate,
      limit: query.limit,
      page: query.page,
      startDate,
    };
  }

  private summaryRange(query: ReportSummaryQueryDto): PeriodRange {
    if (Boolean(query.startDate) !== Boolean(query.endDate)) {
      throw new BadRequestException('startDate and endDate must be supplied together');
    }
    if (query.startDate && query.endDate) {
      const startDate = new Date(query.startDate);
      const endDate = new Date(query.endDate);
      if (startDate > endDate) {
        throw new BadRequestException('startDate must not be after endDate');
      }
      const duration = endDate.getTime() - startDate.getTime();
      return {
        bucket: this.bucketForRange(startDate, endDate),
        endDate,
        previousStartDate: new Date(startDate.getTime() - duration),
        startDate,
      };
    }
    return this.presetRange(query.period);
  }

  private presetRange(period: ReportPeriod): PeriodRange {
    const endDate = new Date();
    const startDate = new Date(endDate);
    let bucket: PeriodRange['bucket'];
    switch (period) {
      case ReportPeriod.SEVEN_DAYS:
        startDate.setUTCDate(startDate.getUTCDate() - 7);
        bucket = 'day';
        break;
      case ReportPeriod.THIRTY_DAYS:
        startDate.setUTCDate(startDate.getUTCDate() - 30);
        bucket = 'day';
        break;
      case ReportPeriod.THREE_MONTHS:
        startDate.setUTCMonth(startDate.getUTCMonth() - 3);
        bucket = 'week';
        break;
      case ReportPeriod.YEAR:
        startDate.setUTCFullYear(startDate.getUTCFullYear() - 1);
        bucket = 'month';
        break;
    }
    const previousStartDate = new Date(
      startDate.getTime() - (endDate.getTime() - startDate.getTime()),
    );
    return { bucket, endDate, previousStartDate, startDate };
  }

  private bucketForRange(startDate?: Date, endDate?: Date): ReportTrendBucket {
    if (!startDate || !endDate) return 'month';
    const days = (endDate.getTime() - startDate.getTime()) / 86_400_000;
    if (days <= 31) return 'day';
    if (days <= 120) return 'week';
    return 'month';
  }

  private label(date: Date, range: PeriodRange): string {
    const days = (range.endDate.getTime() - range.startDate.getTime()) / 86_400_000;
    if (range.bucket === 'day' && days <= 8) {
      return new Intl.DateTimeFormat('en', { timeZone: 'UTC', weekday: 'short' }).format(date);
    }
    if (range.bucket === 'month') {
      return new Intl.DateTimeFormat('en', { month: 'short', timeZone: 'UTC' }).format(date);
    }
    return new Intl.DateTimeFormat('en', {
      day: '2-digit',
      month: 'short',
      timeZone: 'UTC',
    }).format(date);
  }

  private round(value: number): number {
    return Math.round((value + Number.EPSILON) * 100) / 100;
  }
}
