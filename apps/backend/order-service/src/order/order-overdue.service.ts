import { timingSafeEqual } from 'node:crypto';

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import type { Model } from 'mongoose';

import { OrderStatus } from './enums';
import { OrderMongoose } from './order.schema';

export interface OverdueAlertResult {
  readonly shops: number;
  readonly orders: number;
}

/** Orders that are still being worked on; Delivered/Cancelled/Draft are not "late". */
const OPEN_STATUSES: readonly OrderStatus[] = [
  OrderStatus.RECEIVED,
  OrderStatus.ASSIGNED,
  OrderStatus.ACCEPTED,
  OrderStatus.IN_PROGRESS,
  OrderStatus.READY,
  OrderStatus.OUT_FOR_DELIVERY,
];

/**
 * Once a day (a server cron calls it) tells each shop's owners how many orders
 * are past their expected delivery date. Best effort: a push problem is logged,
 * never thrown.
 */
@Injectable()
export class OrderOverdueService {
  private readonly logger = new Logger(OrderOverdueService.name);

  constructor(
    @InjectModel(OrderMongoose.name) private readonly orders: Model<OrderMongoose>,
    private readonly configService: ConfigService,
  ) {}

  isAuthorised(provided: string | undefined): boolean {
    const expected = this.configService.get<string>('INTERNAL_SERVICE_SECRET');
    if (!expected || !provided) return false;
    const a = Buffer.from(provided, 'utf8');
    const b = Buffer.from(expected, 'utf8');
    return a.length === b.length && timingSafeEqual(a, b);
  }

  async alertOwners(now: Date = new Date()): Promise<OverdueAlertResult> {
    const startOfToday = new Date(now);
    startOfToday.setUTCHours(0, 0, 0, 0);
    const rows = await this.orders
      .aggregate<{ _id: unknown; count: number }>([
        {
          $match: {
            status: { $in: OPEN_STATUSES },
            expectedDeliveryDate: { $lt: startOfToday },
          },
        },
        { $group: { _id: '$tenantId', count: { $sum: 1 } } },
      ])
      .exec();

    let orders = 0;
    for (const row of rows) {
      orders += row.count;
      await this.push(String(row._id), row.count);
    }
    return { shops: rows.length, orders };
  }

  private async push(tenantId: string, count: number): Promise<void> {
    const secret = this.configService.get<string>('INTERNAL_SERVICE_SECRET');
    const base = this.configService
      .get<string>('NOTIFICATION_SERVICE_BASE_URL', 'http://localhost:3005')
      .replace(/\/$/, '');
    try {
      const response = await fetch(`${base}/api/v1/internal/push`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-internal-secret': secret ?? '' },
        body: JSON.stringify({
          audience: { tenantId, ownersOnly: true },
          title: 'Orders running late',
          body: `${count} ${count === 1 ? 'order is' : 'orders are'} past the delivery date`,
          data: { type: 'orders_overdue', count: String(count) },
        }),
        signal: AbortSignal.timeout(5_000),
      });
      if (!response.ok) this.logger.warn(`Overdue push refused: HTTP ${response.status}`);
    } catch (error) {
      this.logger.warn(
        `Overdue push failed: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
