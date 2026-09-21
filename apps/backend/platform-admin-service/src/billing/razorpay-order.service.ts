import { Injectable } from '@nestjs/common';

import { RazorpayClientFactory } from './razorpay-client.factory';
import type { BillingChargeGateway, CreateChargeInput, CreatedCharge } from './billing.types';

/**
 * Orders API implementation of BillingChargeGateway: one Razorpay Order
 * created per billing cycle, manually triggered via create-order. This is
 * the ONLY place that calls razorpay.orders.create — if this moves to the
 * Subscriptions API (auto-recurring) later, only this class changes.
 */
@Injectable()
export class RazorpayOrderService implements BillingChargeGateway {
  constructor(private readonly clientFactory: RazorpayClientFactory) {}

  async createChargeForCycle(input: CreateChargeInput): Promise<CreatedCharge> {
    const razorpay = this.clientFactory.getClient();

    const order = await razorpay.orders.create({
      amount: input.amountInPaise,
      currency: input.currency,
      receipt: input.receipt,
      notes: input.notes,
    });

    return { gatewayOrderId: order.id, status: order.status };
  }
}
