import {
  BadGatewayException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { DEFAULT_PAGE_NUMBER, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } from '@nexoraa/constants';
import {
  Permissions,
  hasPermission,
  isBranchManagerRole,
  isCashierRole,
  isOwnerRole,
  isStaffRole,
} from '@nexoraa/shared';
import type { PaginatedResult } from '@nexoraa/types';
import { FilterQuery, Model, Types } from 'mongoose';

import { PaymentOwnerLookupService } from './payment-owner.service';
import { PaymentMongoose, type PaymentDocument } from './payment.schema';
import type {
  CreateAdvancePaymentInput,
  PaymentListQuery,
  PaymentMethod,
  PaymentRecord,
  PaymentScope,
  PaymentStatistics,
} from './payment.types';

const METHODS = new Set<PaymentMethod>(['Cash', 'Card', 'UPI']);
const PAYMENT_TYPES = new Set(['Advance']);
const PAYMENT_STATUSES = new Set(['Pending', 'Successful', 'Failed']);

interface NotifyInput {
  readonly type: string;
  readonly title: string;
  readonly message: string;
  readonly entityType: string;
  readonly entityId: string;
  readonly orderId?: string;
}

@Injectable()
export class PaymentService {
  private readonly logger = new Logger(PaymentService.name);

  constructor(
    @InjectModel(PaymentMongoose.name)
    private readonly payments: Model<PaymentDocument>,
    private readonly config: ConfigService,
    private readonly ownerLookup: PaymentOwnerLookupService,
  ) {}

  async createAdvance(
    scope: PaymentScope,
    idempotencyKey: string | undefined,
    input: CreateAdvancePaymentInput,
  ): Promise<Record<string, unknown>> {
    this.assertWrite(scope);
    const key = idempotencyKey?.trim();
    if (!key || key.length > 160) throw new BadRequestException('Idempotency-Key is required');
    const orderId = this.objectId(input.orderId, 'orderId');
    const customerId = this.objectId(input.customerId, 'customerId');
    const amountMinor = Number(input.amountMinor);
    if (!Number.isSafeInteger(amountMinor) || amountMinor <= 0) {
      throw new BadRequestException('amountMinor must be a positive safe integer');
    }
    if (input.paymentType !== 'Advance') {
      throw new BadRequestException('paymentType must be Advance');
    }
    if (typeof input.method !== 'string' || !METHODS.has(input.method as PaymentMethod)) {
      throw new BadRequestException('Unsupported payment method');
    }
    const method = input.method as PaymentMethod;
    if (input.currency !== undefined && typeof input.currency !== 'string') {
      throw new BadRequestException('currency must be an ISO-4217 code');
    }
    const currency = input.currency?.toUpperCase() ?? 'INR';
    if (currency !== 'INR') throw new BadRequestException('Order currency must be INR');

    let payment = await this.payments
      .findOne({ tenantId: scope.tenantId, idempotencyKey: key, paymentType: 'Advance' })
      .exec();
    if (payment) {
      this.assertSamePayment(payment, orderId, customerId, amountMinor, method);
    } else {
      const order = await this.order(scope, orderId);
      if (String(order.tenantId) !== scope.tenantId || String(order.branchId) !== scope.branchId) {
        throw new ForbiddenException('Order is outside the authenticated scope');
      }
      if (String(order.customerId) !== customerId) {
        throw new BadRequestException('Payment customer does not match the order');
      }
      const outstandingMinor = Math.round(Number(order.outstandingAmount) * 100);
      if (amountMinor > outstandingMinor) {
        throw new BadRequestException('Payment amount cannot exceed the order outstanding balance');
      }
      const id = new Types.ObjectId();
      try {
        payment = await this.payments.create({
          _id: id,
          amountMinor,
          branchId: scope.branchId,
          currency,
          customerId: new Types.ObjectId(customerId),
          idempotencyKey: key,
          method,
          orderId: new Types.ObjectId(orderId),
          paymentNumber: `PAY-${id.toHexString().toUpperCase()}`,
          paymentType: 'Advance',
          recordedBy: new Types.ObjectId(scope.actorId),
          status: 'Pending',
          tenantId: new Types.ObjectId(scope.tenantId),
        });
        {
          const input: NotifyInput = {
            entityId: String(payment._id),
            entityType: 'Payment',
            message: `A payment of ${(amountMinor / 100).toFixed(2)} ${currency} is pending confirmation for order ${this.orderNumberOf(order, orderId)}.`,
            orderId,
            title: 'Payment pending',
            type: 'PaymentPending',
          };
          this.notify(scope, this.createdByOf(order), input);
          this.notifyOwner(scope, this.createdByOf(order), input);
        }
      } catch (error) {
        if (!this.isDuplicateKey(error)) throw error;
        payment = await this.payments
          .findOne({ tenantId: scope.tenantId, idempotencyKey: key, paymentType: 'Advance' })
          .exec();
        if (!payment) throw new ConflictException('Payment creation conflicted');
        this.assertSamePayment(payment, orderId, customerId, amountMinor, method);
      }
    }

    const projectedOrder = await this.project(scope, orderId, String(payment._id), amountMinor);
    if (payment.status !== 'Successful') {
      payment.status = 'Successful';
      await payment.save();
      {
        const input: NotifyInput = {
          entityId: String(payment._id),
          entityType: 'Payment',
          message: `Payment of ${(amountMinor / 100).toFixed(2)} ${currency} received for order ${this.orderNumberOf(projectedOrder, orderId)}.`,
          orderId,
          title: 'Payment received',
          type: 'PaymentReceived',
        };
        this.notify(scope, this.createdByOf(projectedOrder), input);
        this.notifyOwner(scope, this.createdByOf(projectedOrder), input);
      }
    }
    return {
      payment: this.paymentResponse(payment),
      order: projectedOrder,
    };
  }

  async list(
    scope: PaymentScope,
    input: Record<string, unknown>,
  ): Promise<PaginatedResult<PaymentRecord>> {
    this.assertRead(scope);
    const query = this.parseListQuery(input);
    const filter: FilterQuery<PaymentDocument> = {
      branchId: scope.branchId,
      tenantId: new Types.ObjectId(scope.tenantId),
      ...(query.status ? { status: query.status } : {}),
      ...(query.paymentType ? { paymentType: query.paymentType } : {}),
      ...(query.customerId ? { customerId: new Types.ObjectId(query.customerId) } : {}),
      ...(query.orderId ? { orderId: new Types.ObjectId(query.orderId) } : {}),
    };
    const skip = (query.page - 1) * query.limit;
    const [documents, total] = await Promise.all([
      this.payments
        .find(filter)
        .sort({ createdAt: query.sortDirection, _id: query.sortDirection })
        .skip(skip)
        .limit(query.limit)
        .lean()
        .exec(),
      this.payments.countDocuments(filter).exec(),
    ]);
    const items = await this.enrichWithOrderDetails(scope, documents);
    return {
      items,
      limit: query.limit,
      page: query.page,
      total,
      totalPages: Math.ceil(total / query.limit),
    };
  }

  async statistics(scope: PaymentScope, customerId?: string): Promise<PaymentStatistics> {
    this.assertRead(scope);
    const customerObjectId = customerId
      ? new Types.ObjectId(this.objectId(customerId, 'customerId'))
      : undefined;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const [result] = await this.payments
      .aggregate<PaymentStatistics>([
        {
          $match: {
            tenantId: new Types.ObjectId(scope.tenantId),
            branchId: scope.branchId,
            ...(customerObjectId ? { customerId: customerObjectId } : {}),
          },
        },
        {
          $group: {
            _id: null,
            totalBills: { $sum: 1 },
            successfulBills: {
              $sum: { $cond: [{ $eq: ['$status', 'Successful'] }, 1, 0] },
            },
            todayCollectedCount: {
              $sum: {
                $cond: [
                  {
                    $and: [
                      { $eq: ['$status', 'Successful'] },
                      { $gte: ['$createdAt', today] },
                      { $lt: ['$createdAt', tomorrow] },
                    ],
                  },
                  1,
                  0,
                ],
              },
            },
            todayCollectedMinor: {
              $sum: {
                $cond: [
                  {
                    $and: [
                      { $eq: ['$status', 'Successful'] },
                      { $gte: ['$createdAt', today] },
                      { $lt: ['$createdAt', tomorrow] },
                    ],
                  },
                  '$amountMinor',
                  0,
                ],
              },
            },
            yesterdayCollectedMinor: {
              $sum: {
                $cond: [
                  {
                    $and: [
                      { $eq: ['$status', 'Successful'] },
                      { $gte: ['$createdAt', yesterday] },
                      { $lt: ['$createdAt', today] },
                    ],
                  },
                  '$amountMinor',
                  0,
                ],
              },
            },
          },
        },
        { $project: { _id: 0 } },
      ])
      .exec();
    return (
      result ?? {
        successfulBills: 0,
        todayCollectedCount: 0,
        todayCollectedMinor: 0,
        totalBills: 0,
        yesterdayCollectedMinor: 0,
      }
    );
  }

  private parseListQuery(input: Record<string, unknown>): PaymentListQuery {
    const page = this.positiveInt(input.page, DEFAULT_PAGE_NUMBER, 1);
    const limit = this.positiveInt(input.limit, DEFAULT_PAGE_SIZE, 1, MAX_PAGE_SIZE);
    const status = this.enumValue(input.status, PAYMENT_STATUSES, 'status') as
      | PaymentListQuery['status']
      | undefined;
    const paymentType = this.enumValue(input.paymentType, PAYMENT_TYPES, 'paymentType') as
      | PaymentListQuery['paymentType']
      | undefined;
    const customerId = this.optionalObjectId(input.customerId, 'customerId');
    const orderId = this.optionalObjectId(input.orderId, 'orderId');
    const sortDirection = input.sortDirection === 'asc' || input.sortDirection === '1' ? 1 : -1;
    return { customerId, limit, orderId, page, paymentType, sortDirection, status };
  }

  private async enrichWithOrderDetails(
    scope: PaymentScope,
    documents: readonly PaymentDocument[],
  ): Promise<PaymentRecord[]> {
    const orderIds = [...new Set(documents.map((document) => String(document.orderId)))];
    const orders = new Map<string, Record<string, unknown>>();
    await Promise.all(
      orderIds.map(async (orderId) => {
        try {
          orders.set(orderId, await this.order(scope, orderId));
        } catch {
          // Order Service is unreachable or the order is gone; leave enrichment fields
          // undefined for these payments rather than fabricating a name/order number.
        }
      }),
    );
    return documents.map((document) => {
      const orderId = String(document.orderId);
      const order = orders.get(orderId);
      const customerSnapshot =
        typeof order?.customerSnapshot === 'object' && order.customerSnapshot !== null
          ? (order.customerSnapshot as Record<string, unknown>)
          : undefined;
      const customerName =
        typeof customerSnapshot?.name === 'string' ? customerSnapshot.name : undefined;
      const orderNumber = typeof order?.orderNumber === 'string' ? order.orderNumber : undefined;
      return {
        amountMinor: document.amountMinor,
        branchId: document.branchId,
        createdAt: document.createdAt,
        currency: document.currency,
        customerId: String(document.customerId),
        customerName,
        id: String(document._id),
        method: document.method,
        orderId,
        orderNumber,
        paymentNumber: document.paymentNumber,
        paymentType: document.paymentType,
        recordedBy: String(document.recordedBy),
        status: document.status,
        tenantId: String(document.tenantId),
        updatedAt: document.updatedAt,
      };
    });
  }

  private positiveInt(value: unknown, fallback: number, min: number, max?: number): number {
    const parsed = typeof value === 'string' || typeof value === 'number' ? Number(value) : NaN;
    if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) return fallback;
    const clampedMin = Math.max(parsed, min);
    return max === undefined ? clampedMin : Math.min(clampedMin, max);
  }

  private enumValue<T extends string>(value: unknown, allowed: Set<string>, field: string): T {
    if (value === undefined) return undefined as unknown as T;
    if (typeof value !== 'string' || !allowed.has(value)) {
      throw new BadRequestException(`${field} is invalid`);
    }
    return value as T;
  }

  private optionalObjectId(value: unknown, field: string): string | undefined {
    if (value === undefined) return undefined;
    if (typeof value !== 'string' || !Types.ObjectId.isValid(value)) {
      throw new BadRequestException(`${field} must be a MongoDB ObjectId`);
    }
    return value;
  }

  private assertRead(scope: PaymentScope): void {
    if (
      !(
        isOwnerRole(scope.roleCode) ||
        isBranchManagerRole(scope.roleCode) ||
        isCashierRole(scope.roleCode)
      ) ||
      !(
        hasPermission(scope.roleCode, scope.permissions, Permissions.paymentsRead) ||
        scope.permissions.includes(Permissions.ordersRead) ||
        (isCashierRole(scope.roleCode) && scope.permissions.includes('process:payments'))
      )
    ) {
      throw new ForbiddenException('Payment read permission is required');
    }
  }

  private async order(scope: PaymentScope, orderId: string): Promise<Record<string, unknown>> {
    const response = await this.request(`${this.orderBaseUrl()}/api/v1/orders/${orderId}`, {
      authorization: scope.authorization,
      'x-branch-id': scope.branchId,
    });
    return this.record(this.unwrap(response), 'Order Service returned an invalid order');
  }

  private async project(
    scope: PaymentScope,
    orderId: string,
    paymentId: string,
    amountMinor: number,
  ): Promise<Record<string, unknown>> {
    const key = this.config.get<string>('PAYMENT_PROJECTION_KEY');
    if (!key) throw new BadGatewayException('Payment projection integration is not configured');
    const response = await this.request(
      `${this.orderBaseUrl()}/api/v1/orders/${orderId}/payment-projection`,
      {
        authorization: scope.authorization,
        'content-type': 'application/json',
        'x-branch-id': scope.branchId,
        'x-payment-projection-key': key,
      },
      JSON.stringify({ amountMinor, paymentId }),
    );
    return this.record(this.unwrap(response), 'Order Service returned an invalid projection');
  }

  private async request(
    url: string,
    headers: Record<string, string>,
    body?: string,
  ): Promise<unknown> {
    let response: Response;
    try {
      response = await fetch(url, { body, headers, method: body ? 'POST' : 'GET' });
    } catch {
      throw new BadGatewayException('Order Service is unavailable');
    }
    if (response.status === 404) throw new NotFoundException('Order not found');
    if (response.status === 409) throw new ConflictException('Payment exceeds outstanding amount');
    if (!response.ok) throw new BadGatewayException('Order Service rejected payment projection');
    return response.json();
  }

  private unwrap(value: unknown): unknown {
    const record =
      typeof value === 'object' && value !== null ? (value as Record<string, unknown>) : undefined;
    return record && 'data' in record ? record.data : value;
  }

  private record(value: unknown, message: string): Record<string, unknown> {
    if (typeof value !== 'object' || value === null || Array.isArray(value)) {
      throw new BadGatewayException(message);
    }
    return value as Record<string, unknown>;
  }

  private objectId(value: unknown, field: string): string {
    if (typeof value !== 'string' || !Types.ObjectId.isValid(value)) {
      throw new BadRequestException(`${field} must be a MongoDB ObjectId`);
    }
    return value;
  }

  private paymentResponse(payment: PaymentDocument): Record<string, unknown> {
    return {
      amountMinor: payment.amountMinor,
      branchId: payment.branchId,
      currency: payment.currency,
      id: String(payment._id),
      method: payment.method,
      orderId: String(payment.orderId),
      paymentNumber: payment.paymentNumber,
      paymentType: payment.paymentType,
      status: payment.status,
      tenantId: String(payment.tenantId),
    };
  }

  private assertSamePayment(
    payment: PaymentDocument,
    orderId: string,
    customerId: string,
    amountMinor: number,
    method: PaymentMethod,
  ): void {
    if (
      String(payment.orderId) !== orderId ||
      String(payment.customerId) !== customerId ||
      payment.amountMinor !== amountMinor ||
      payment.method !== method
    ) {
      throw new ConflictException('Idempotency-Key was already used for another payment');
    }
  }

  private isDuplicateKey(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as { code?: unknown }).code === 11000
    );
  }

  private orderBaseUrl(): string {
    return this.config
      .get<string>('ORDER_SERVICE_BASE_URL', 'http://localhost:3007')
      .replace(/\/$/, '');
  }

  private assertWrite(scope: PaymentScope): void {
    if (
      !(
        isOwnerRole(scope.roleCode) ||
        isBranchManagerRole(scope.roleCode) ||
        isCashierRole(scope.roleCode) ||
        isStaffRole(scope.roleCode)
      ) ||
      !(
        hasPermission(scope.roleCode, scope.permissions, Permissions.paymentsWrite) ||
        hasPermission(scope.roleCode, scope.permissions, Permissions.ordersWrite) ||
        scope.permissions.includes(Permissions.ordersWrite) ||
        scope.permissions.includes('orders:write') ||
        scope.permissions.includes('payments:write') ||
        (isCashierRole(scope.roleCode) && scope.permissions.includes('process:payments')) ||
        (isStaffRole(scope.roleCode) && scope.permissions.length === 0)
      )
    ) {
      throw new ForbiddenException('Payment write permission is required');
    }
  }

  private createdByOf(order: Record<string, unknown>): string | undefined {
    return typeof order.createdBy === 'string' && order.createdBy ? order.createdBy : undefined;
  }

  private orderNumberOf(order: Record<string, unknown>, fallback: string): string {
    return typeof order.orderNumber === 'string' && order.orderNumber
      ? order.orderNumber
      : fallback;
  }

  /**
   * Fire-and-forget notification delivery: forwards the acting user's own bearer token
   * (same service-to-service pattern used for the Order Service calls above), so the
   * created notification lands in the caller's own verified tenant/branch. Never blocks or
   * fails the payment operation that triggered it, and never notifies the actor about their
   * own action.
   */
  private notify(scope: PaymentScope, recipientId: string | undefined, input: NotifyInput): void {
    if (!recipientId || recipientId === scope.actorId) return;
    void this.sendNotification(scope, recipientId, input);
  }

  /**
   * Notifies the tenant Owner in addition to whichever recipient `notify()`
   * already targeted for this same event. Unlike `notify()`, this never
   * skips the Owner for being the acting user — the Owner wants visibility
   * into everything happening in their tenant, including their own actions
   * (see NEX-142 business rule). It only skips when the existing recipient
   * already is the Owner and will actually receive that notification (i.e.
   * that recipient wasn't itself self-skipped), to avoid a duplicate.
   */
  private notifyOwner(
    scope: PaymentScope,
    existingRecipientId: string | undefined,
    input: NotifyInput,
  ): void {
    void this.deliverToOwner(scope, existingRecipientId, input);
  }

  private async deliverToOwner(
    scope: PaymentScope,
    existingRecipientId: string | undefined,
    input: NotifyInput,
  ): Promise<void> {
    let ownerId: string | undefined;
    try {
      ownerId = await this.ownerLookup.findOwnerId(scope.tenantId);
    } catch (error) {
      this.logger.warn(`Failed to resolve tenant owner: ${(error as Error).message}`);
      return;
    }
    if (!ownerId) return;
    const existingRecipientWillDeliver =
      existingRecipientId !== undefined && existingRecipientId !== scope.actorId;
    if (existingRecipientWillDeliver && existingRecipientId === ownerId) return;
    await this.sendNotification(scope, ownerId, input);
  }

  private async sendNotification(
    scope: PaymentScope,
    recipientId: string,
    input: NotifyInput,
  ): Promise<void> {
    try {
      const baseUrl = this.config
        .get<string>('NOTIFICATION_SERVICE_BASE_URL', 'http://localhost:3015')
        .replace(/\/$/, '');
      const response = await fetch(`${baseUrl}/api/v1/notifications`, {
        body: JSON.stringify({ recipientId, ...input }),
        headers: {
          authorization: scope.authorization,
          'content-type': 'application/json',
          'x-branch-id': scope.branchId,
        },
        method: 'POST',
        signal: AbortSignal.timeout(5000),
      });
      if (!response.ok) {
        this.logger.warn(
          `Notification Service rejected a ${input.type} notification: ${response.status}`,
        );
      }
    } catch (error) {
      this.logger.warn(
        `Failed to deliver a ${input.type} notification: ${(error as Error).message}`,
      );
    }
  }
}
