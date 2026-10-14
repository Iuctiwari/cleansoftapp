import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { OrderRecord } from './order.types';

/** The push body is cut at 300 characters by notification-service. */
const MAX_BODY = 300;

const text = (value: unknown): string | undefined =>
  typeof value === 'string' && value.trim() ? value.trim() : undefined;

const rupees = (value: number): string =>
  `Rs. ${value.toLocaleString('en-IN', { maximumFractionDigits: 2 })}`;

/**
 * Sends a new order's bill (items and total) to the customer's phone, when the
 * customer has the app. Best effort: a push problem is logged, never thrown, so
 * it can never fail the shop creating the order.
 */
@Injectable()
export class OrderBillPushService {
  private readonly logger = new Logger(OrderBillPushService.name);

  constructor(private readonly configService: ConfigService) {}

  sendBill(order: OrderRecord, shopName?: string): void {
    const consumerId = text(order.customerSnapshot.consumerId);
    if (!consumerId) return;
    void this.push(consumerId, order, shopName);
  }

  billBody(order: OrderRecord): string {
    const lines = order.items.map((item) => {
      const service = text(item.serviceSnapshot.name) ?? 'Service';
      const category = text(item.itemCategorySnapshot.name);
      const amount = item.quantity ? ` x${item.quantity}` : item.weight ? ` ${item.weight}kg` : '';
      return `${service}${category ? ` - ${category}` : ''}${amount}: ${rupees(item.lineTotal)}`;
    });
    const total = `Total ${rupees(order.grandTotal)}`;
    const discount = order.discount > 0 ? ` (discount ${rupees(order.discount)})` : '';
    const footer = `${total}${discount}`;

    let body = '';
    let shown = 0;
    for (const line of lines) {
      const remaining = lines.length - shown - 1;
      const reserve = remaining > 0 ? `\n+${remaining} more` : '';
      if (`${body}${body ? '\n' : ''}${line}${reserve}\n${footer}`.length > MAX_BODY) break;
      body += `${body ? '\n' : ''}${line}`;
      shown += 1;
    }
    const hidden = lines.length - shown;
    return `${body}${hidden > 0 ? `${body ? '\n' : ''}+${hidden} more` : ''}\n${footer}`.trim();
  }

  private async push(consumerId: string, order: OrderRecord, shopName?: string): Promise<void> {
    const secret = this.configService.get<string>('INTERNAL_SERVICE_SECRET');
    if (!secret) return;
    const base = this.configService
      .get<string>('NOTIFICATION_SERVICE_BASE_URL', 'http://localhost:3005')
      .replace(/\/$/, '');
    try {
      const response = await fetch(`${base}/api/v1/internal/push`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-internal-secret': secret },
        body: JSON.stringify({
          audience: { consumerId },
          title: `${shopName ? `${shopName}: ` : ''}Your bill for ${order.orderNumber}`,
          body: this.billBody(order),
          data: {
            type: 'order_bill',
            orderId: order.id,
            orderNumber: order.orderNumber,
            grandTotal: String(order.grandTotal),
          },
        }),
        signal: AbortSignal.timeout(5_000),
      });
      if (!response.ok) this.logger.warn(`Bill push refused: HTTP ${response.status}`);
    } catch (error) {
      this.logger.warn(
        `Bill push failed: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
