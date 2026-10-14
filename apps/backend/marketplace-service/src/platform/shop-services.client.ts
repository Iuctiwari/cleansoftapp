import {
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { ShopPrincipal } from './marketplace.types';

const REQUEST_TIMEOUT_MS = 5_000;

export interface OnlineCustomerInput {
  readonly consumerId: string;
  readonly name: string;
  readonly mobile: string;
  readonly email?: string;
  readonly address?: string;
}

export interface ShopCustomer {
  readonly id: string;
  readonly name: string;
  readonly mobile: string;
}

export interface LinkedOrder {
  readonly orderId: string;
  readonly orderNumber: string;
  readonly customerId: string;
}

/** Calls into the shop's own services (customer list, orders). */
@Injectable()
export class ShopServicesClient {
  private readonly logger = new Logger(ShopServicesClient.name);

  constructor(private readonly configService: ConfigService) {}

  /**
   * Puts the online customer on the branch's customer list (or links the
   * shop's existing record with the same mobile). Returns undefined when
   * customer-service is unreachable — the request still goes through and the
   * link is retried when the shop accepts it.
   */
  async linkOnlineCustomer(
    tenantId: string,
    branchId: string,
    input: OnlineCustomerInput,
  ): Promise<string | undefined> {
    const baseUrl = this.configService.get<string>(
      'CUSTOMER_SERVICE_BASE_URL',
      'http://localhost:3003',
    );
    const sharedSecret = this.configService.get<string>('PLATFORM_ADMIN_INTERNAL_KEY');
    try {
      const response = await fetch(
        `${baseUrl.replace(/\/$/, '')}/internal/tenants/${encodeURIComponent(tenantId)}/branches/${encodeURIComponent(branchId)}/online-customers`,
        {
          method: 'POST',
          headers: {
            'content-type': 'application/json',
            ...(sharedSecret ? { 'x-platform-admin-key': sharedSecret } : {}),
          },
          body: JSON.stringify(input),
          signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
        },
      );
      if (!response.ok) {
        this.logger.warn(`Linking online customer failed: HTTP ${response.status}`);
        return undefined;
      }
      const body = (await response.json()) as {
        readonly customerId?: string;
        readonly data?: { readonly customerId?: string };
      };
      return body.data?.customerId ?? body.customerId;
    } catch (error) {
      this.logger.warn(`Linking online customer failed: ${String(error)}`);
      return undefined;
    }
  }

  /** The shop's own customer (walk-in), read with the shop user's token so it only works inside their branch. */
  async getCustomer(shop: ShopPrincipal, customerId: string): Promise<ShopCustomer> {
    const baseUrl = this.configService.get<string>(
      'CUSTOMER_SERVICE_BASE_URL',
      'http://localhost:3003',
    );
    let response: Response;
    try {
      response = await fetch(
        `${baseUrl.replace(/\/$/, '')}/customers/${encodeURIComponent(customerId)}`,
        {
          headers: { authorization: shop.authorization, 'x-branch-id': shop.branchId },
          signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
        },
      );
    } catch {
      throw new ServiceUnavailableException('Customer service is unavailable');
    }
    if (response.status === 404 || response.status === 400 || response.status === 403) {
      throw new NotFoundException('Customer not found in this branch');
    }
    if (!response.ok) {
      throw new ServiceUnavailableException(`Customer service returned HTTP ${response.status}`);
    }
    const body = (await response.json()) as Record<string, unknown> & {
      readonly data?: Record<string, unknown>;
    };
    const customer = (body.data ?? body) as {
      readonly id?: string;
      readonly name?: string;
      readonly mobile?: string;
    };
    if (!customer.id || !customer.name) {
      throw new ServiceUnavailableException('Customer service returned an unexpected response');
    }
    return { id: customer.id, name: customer.name, mobile: customer.mobile ?? '' };
  }

  /**
   * Reads the order with the shop user's own token, so it only succeeds for
   * an order in the branch they are signed in to.
   */
  async findShopOrder(shop: ShopPrincipal, orderId: string): Promise<LinkedOrder> {
    const baseUrl = this.configService.get<string>(
      'ORDER_SERVICE_BASE_URL',
      'http://localhost:3007/api',
    );
    let response: Response;
    try {
      response = await fetch(
        `${baseUrl.replace(/\/$/, '')}/v1/orders/${encodeURIComponent(orderId)}`,
        {
          headers: { authorization: shop.authorization, 'x-branch-id': shop.branchId },
          signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
        },
      );
    } catch {
      throw new ServiceUnavailableException('Order service is unavailable');
    }
    if (response.status === 404 || response.status === 400) {
      throw new NotFoundException('Order not found in this branch');
    }
    if (response.status === 403) {
      throw new ConflictException('This order belongs to a different branch');
    }
    if (!response.ok) {
      throw new ServiceUnavailableException(`Order service returned HTTP ${response.status}`);
    }

    const body = (await response.json()) as Record<string, unknown> & {
      readonly data?: Record<string, unknown>;
    };
    const order = (body.data ?? body) as {
      readonly id?: string;
      readonly orderNumber?: string;
      readonly customerId?: string;
    };
    if (!order.id || !order.orderNumber) {
      throw new ServiceUnavailableException('Order service returned an unexpected response');
    }
    return {
      orderId: order.id,
      orderNumber: order.orderNumber,
      customerId: order.customerId ?? '',
    };
  }
}
