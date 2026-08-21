import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SortDirection } from '@nexoraa/constants';

import type { AssignOrderDto } from './dtos/assign-order.dto';
import type { CancelOrderDto } from './dtos/cancel-order.dto';
import type { CreateOrderDto } from './dtos/create-order.dto';
import type { OrderItemDto } from './dtos/order-item.dto';
import type { OrderQueryDto } from './dtos/order-query.dto';
import type { UpdateOrderStatusDto } from './dtos/update-order-status.dto';
import type { UpdateOrderDto } from './dtos/update-order.dto';
import { OrderStatus } from './enums';
import { OrderAuditService } from './order-audit.service';
import { OrderOwnerLookupService } from './order-owner.service';
import {
  CATALOG_PRICING_TYPES,
  ORDER_DEPENDENCIES,
  ORDER_REPOSITORY,
  type CatalogQuote,
  type CatalogPricingType,
  type OrderDependencies,
  type OrderPage,
  type OrderRecord,
  type OrderRepository,
  type OrderScope,
  type OrderTotals,
  type PersistedOrderItem,
  type StatusHistoryRecord,
} from './order.types';

const WRITE_ROLES = new Set(['tenant_owner', 'branch_manager', 'cashier']);
const MANAGE_ROLES = new Set(['tenant_owner', 'branch_manager']);
const STAFF_ROLE = 'staff';
const ADDITIONAL_SERVICE_SURCHARGE = 10;

interface NotifyInput {
  readonly type: string;
  readonly title: string;
  readonly message: string;
  readonly entityType: string;
  readonly entityId: string;
  readonly orderId?: string;
}

const STATUS_NOTIFICATIONS: Readonly<
  Partial<Record<OrderStatus, Pick<NotifyInput, 'type' | 'title' | 'message'>>>
> = {
  [OrderStatus.IN_PROGRESS]: {
    message: 'is now in progress',
    title: 'Order in progress',
    type: 'OrderInProgress',
  },
  [OrderStatus.OUT_FOR_DELIVERY]: {
    message: 'is out for delivery',
    title: 'Order out for delivery',
    type: 'OrderInDelivery',
  },
  [OrderStatus.DELIVERED]: {
    message: 'has been delivered',
    title: 'Delivery completed',
    type: 'DeliveryCompleted',
  },
};

const NEXT_STATUSES: Readonly<Partial<Record<OrderStatus, readonly OrderStatus[]>>> = Object.freeze(
  {
    [OrderStatus.DRAFT]: [OrderStatus.RECEIVED],
    [OrderStatus.RECEIVED]: [OrderStatus.IN_PROGRESS],
    [OrderStatus.IN_PROGRESS]: [OrderStatus.READY],
    [OrderStatus.READY]: [OrderStatus.OUT_FOR_DELIVERY, OrderStatus.DELIVERED],
    [OrderStatus.OUT_FOR_DELIVERY]: [OrderStatus.DELIVERED],
  },
);

@Injectable()
export class OrderService {
  private readonly logger = new Logger(OrderService.name);

  constructor(
    @Inject(ORDER_REPOSITORY) private readonly repository: OrderRepository,
    @Inject(ORDER_DEPENDENCIES) private readonly dependencies: OrderDependencies,
    private readonly audit: OrderAuditService,
    private readonly configService: ConfigService,
    private readonly ownerLookup: OrderOwnerLookupService,
  ) {}

  async create(scope: OrderScope, input: CreateOrderDto): Promise<OrderRecord> {
    this.assertWrite(scope);
    const branch = await this.dependencies.resolveBranch(scope);
    const [customerSnapshot, totals] = await Promise.all([
      this.dependencies.resolveCustomer(scope, input.customerId),
      this.calculateTotals(scope, input.items, input.discount, input.discountPercentage ?? 0),
      ...(input.assignedTo ? [this.dependencies.assertStaffEligible(scope, input.assignedTo)] : []),
    ]);
    const order = await this.repository.create(scope, {
      ...totals,
      assignedTo: input.assignedTo,
      branchCode: branch.code,
      customerId: input.customerId,
      customerSnapshot,
      expectedDeliveryDate: input.expectedDeliveryDate
        ? new Date(input.expectedDeliveryDate)
        : undefined,
    });
    this.audit.record(scope, 'order.created', order.id, {
      assignedTo: order.assignedTo,
      status: order.status,
    });
    if (order.assignedTo) {
      this.notify(scope, order.assignedTo, {
        entityId: order.id,
        entityType: 'Order',
        message: `A new order ${order.orderNumber} has been created and assigned to you.`,
        orderId: order.id,
        title: 'New order assigned',
        type: 'OrderCreated',
      });
    }
    this.notifyOwner(scope, order.assignedTo, {
      entityId: order.id,
      entityType: 'Order',
      message: `Order ${order.orderNumber} has been created.`,
      orderId: order.id,
      title: 'New order created',
      type: 'OrderCreated',
    });
    return order;
  }

  list(scope: OrderScope, query: OrderQueryDto): Promise<OrderPage> {
    this.assertRead(scope);
    if (query.branchId && query.branchId !== scope.branchId) {
      throw new ForbiddenException('Requested branch is outside the authenticated scope');
    }
    return this.repository.list(scope, {
      customerId: query.customerId,
      limit: query.limit,
      page: query.page,
      paymentStatus: query.paymentStatus,
      search: query.search?.trim(),
      sortBy: query.sortBy,
      sortDirection: query.sortDirection === SortDirection.Ascending ? 1 : -1,
      status: query.status,
      ...(scope.roleCode === STAFF_ROLE ? { assignedTo: scope.actorId } : {}),
    });
  }

  async get(scope: OrderScope, id: string): Promise<OrderRecord> {
    this.assertRead(scope);
    const order = await this.repository.findById(
      scope,
      id,
      scope.roleCode === STAFF_ROLE ? scope.actorId : undefined,
    );
    if (!order) throw new NotFoundException('Order not found');
    return order;
  }

  async update(scope: OrderScope, id: string, input: UpdateOrderDto): Promise<OrderRecord> {
    this.assertWrite(scope);
    const existing = await this.get(scope, id);
    if (![OrderStatus.DRAFT, OrderStatus.RECEIVED].includes(existing.status)) {
      throw new ConflictException('Order can only be edited in Draft or Received status');
    }
    if (
      input.items === undefined &&
      input.discount === undefined &&
      input.discountPercentage === undefined &&
      input.expectedDeliveryDate === undefined
    ) {
      throw new BadRequestException('At least one mutable order field is required');
    }

    this.assertDiscountMode(input.discount, input.discountPercentage);
    const discount =
      input.discount ?? (input.discountPercentage !== undefined ? 0 : existing.discount);
    const discountPercentage =
      input.discountPercentage ?? (input.discount !== undefined ? 0 : existing.discountPercentage);
    const totals = input.items
      ? await this.calculateTotals(scope, input.items, discount, discountPercentage, existing)
      : this.recalculateExisting(existing, discount, discountPercentage);
    const order = await this.repository.update(scope, id, existing.status, {
      ...totals,
      expectedDeliveryDate:
        input.expectedDeliveryDate === undefined
          ? existing.expectedDeliveryDate
          : new Date(input.expectedDeliveryDate),
    });
    if (!order) throw new ConflictException('Order changed concurrently');
    this.audit.record(scope, 'order.updated', id);
    return order;
  }

  async changeStatus(
    scope: OrderScope,
    id: string,
    input: UpdateOrderStatusDto,
  ): Promise<OrderRecord> {
    const existing = await this.get(scope, id);
    this.assertTransition(scope, existing);
    if (input.status === OrderStatus.CANCELLED) {
      throw new ConflictException('Use the cancellation endpoint to cancel an order');
    }
    if (!NEXT_STATUSES[existing.status]?.includes(input.status)) {
      throw new ConflictException('Invalid or out-of-sequence order status transition');
    }
    const order = await this.repository.transition(
      scope,
      id,
      existing.status,
      input.status,
      input.note?.trim(),
    );
    if (!order) throw new ConflictException('Order changed concurrently');
    this.audit.record(scope, 'order.status_changed', id, {
      newStatus: input.status,
      previousStatus: existing.status,
    });
    this.notifyStatusChange(scope, order);
    return order;
  }

  async assign(scope: OrderScope, id: string, input: AssignOrderDto): Promise<OrderRecord> {
    this.assertManage(scope);
    const existing = await this.get(scope, id);
    if ([OrderStatus.DELIVERED, OrderStatus.CANCELLED].includes(existing.status)) {
      throw new ConflictException('Terminal orders cannot be reassigned');
    }
    if (existing.assignedTo === input.assignedTo) {
      throw new ConflictException('Order is already assigned to this worker');
    }
    await this.dependencies.assertStaffEligible(scope, input.assignedTo);
    const order = await this.repository.assign(
      scope,
      id,
      input.assignedTo,
      input.dueDate ? new Date(input.dueDate) : undefined,
    );
    if (!order) throw new ConflictException('Order assignment changed concurrently');
    this.audit.record(scope, 'order.assigned', id, { assignedTo: input.assignedTo });
    this.notify(scope, input.assignedTo, {
      entityId: order.id,
      entityType: 'Order',
      message: `You have been assigned to order ${order.orderNumber}.`,
      orderId: order.id,
      title: 'Order assigned to you',
      type: 'WorkerAssigned',
    });
    this.notifyOwner(scope, input.assignedTo, {
      entityId: order.id,
      entityType: 'Order',
      message: `Order ${order.orderNumber} has been assigned to a worker.`,
      orderId: order.id,
      title: 'Worker assigned',
      type: 'WorkerAssigned',
    });
    return order;
  }

  async cancel(scope: OrderScope, id: string, input: CancelOrderDto): Promise<OrderRecord> {
    this.assertManage(scope);
    const existing = await this.get(scope, id);
    if ([OrderStatus.DELIVERED, OrderStatus.CANCELLED].includes(existing.status)) {
      throw new ConflictException('Delivered or cancelled orders cannot be cancelled');
    }
    const reason = input.reason.trim();
    if (!reason) throw new BadRequestException('Cancellation reason is required');
    const order = await this.repository.transition(
      scope,
      id,
      existing.status,
      OrderStatus.CANCELLED,
      reason,
      reason,
    );
    if (!order) throw new ConflictException('Order changed concurrently');
    this.audit.record(scope, 'order.cancelled', id, { previousStatus: existing.status, reason });
    return order;
  }

  async history(scope: OrderScope, id: string): Promise<readonly StatusHistoryRecord[]> {
    await this.get(scope, id);
    return this.repository.history(scope, id);
  }

  async applyPaymentProjection(
    scope: OrderScope,
    id: string,
    paymentId: string,
    amountMinor: number,
  ): Promise<OrderRecord> {
    const amount = this.money(amountMinor / 100);
    const order = await this.repository.applyPaymentProjection(scope, id, paymentId, amount);
    if (!order) {
      throw new ConflictException('Payment exceeds the outstanding order amount');
    }
    this.audit.record(scope, 'order.payment_projection_updated', id, {
      amount,
      paymentId,
    });
    return order;
  }

  private async calculateTotals(
    scope: OrderScope,
    items: readonly OrderItemDto[],
    orderDiscount: number,
    discountPercentage: number,
    existing?: OrderRecord,
  ): Promise<OrderTotals> {
    this.assertDiscountMode(orderDiscount, discountPercentage);
    const quotes = await Promise.all(
      items.map(async (item) => {
        const snapshot = existing?.items.find(
          (candidate) =>
            candidate.serviceId === item.serviceId &&
            candidate.itemCategoryId === item.itemCategoryId,
        );
        if (snapshot) {
          await this.dependencies.validateCatalogReference(
            scope,
            item.serviceId,
            item.itemCategoryId,
          );
          const pricing = snapshot.serviceSnapshot.pricing;
          const taxPercent =
            typeof pricing === 'object' &&
            pricing !== null &&
            'taxPct' in pricing &&
            Number.isFinite(Number(pricing.taxPct))
              ? Number(pricing.taxPct)
              : undefined;
          const pricingType =
            typeof pricing === 'object' && pricing !== null && 'pricingType' in pricing
              ? this.catalogPricingType(pricing.pricingType)
              : undefined;
          return {
            itemCategorySnapshot: snapshot.itemCategorySnapshot,
            serviceSnapshot: snapshot.serviceSnapshot,
            pricingType: pricingType ?? (snapshot.weight === undefined ? 'PerItem' : 'PerKg'),
            taxPercent: taxPercent ?? 0,
            unitPrice: snapshot.unitPrice,
          } satisfies CatalogQuote;
        }
        return this.dependencies.quoteCatalog(scope, item.serviceId, item.itemCategoryId);
      }),
    );
    const serviceCountsByItemCategory = new Map<string, number>();
    const persistedItems = items.map((item, index) => {
      const serviceIndex = serviceCountsByItemCategory.get(item.itemCategoryId) ?? 0;
      serviceCountsByItemCategory.set(item.itemCategoryId, serviceIndex + 1);
      return this.calculateItem(
        item,
        quotes[index],
        serviceIndex === 0 ? quotes[index].unitPrice : ADDITIONAL_SERVICE_SURCHARGE,
      );
    });
    return this.totals(
      persistedItems,
      orderDiscount,
      discountPercentage,
      existing?.paidAmount ?? 0,
    );
  }

  private calculateItem(
    item: OrderItemDto,
    quote: CatalogQuote,
    appliedUnitPrice = quote.unitPrice,
  ): PersistedOrderItem {
    const units = this.unitsForPricing(item, quote.pricingType);
    const base = units * appliedUnitPrice;
    if (item.discount > base) {
      throw new BadRequestException('Line discount cannot exceed the line base amount');
    }
    const taxableLineAmount = base - item.discount;
    const calculatedTax = taxableLineAmount * (quote.taxPercent / 100);
    const lineTotal = this.money(taxableLineAmount + calculatedTax);
    if (lineTotal < 0) throw new BadRequestException('Line total cannot be negative');
    return {
      discount: this.money(item.discount),
      itemCategoryId: item.itemCategoryId,
      itemCategorySnapshot: quote.itemCategorySnapshot,
      lineTotal,
      notes: item.notes?.trim(),
      quantity: item.quantity,
      serviceId: item.serviceId,
      serviceSnapshot: quote.serviceSnapshot,
      tax: this.money(calculatedTax),
      unitPrice: this.money(appliedUnitPrice),
      weight: item.weight,
    };
  }

  private recalculateExisting(
    order: OrderRecord,
    discount = order.discount,
    discountPercentage = order.discountPercentage,
  ): OrderTotals {
    const items: PersistedOrderItem[] = order.items.map((item) => ({
      discount: item.discount,
      itemCategoryId: item.itemCategoryId,
      itemCategorySnapshot: item.itemCategorySnapshot,
      lineTotal: item.lineTotal,
      notes: item.notes,
      quantity: item.quantity,
      serviceId: item.serviceId,
      serviceSnapshot: item.serviceSnapshot,
      tax: item.tax,
      unitPrice: item.unitPrice,
      weight: item.weight,
    }));
    return this.totals(items, discount, discountPercentage, order.paidAmount);
  }

  private unitsForPricing(item: OrderItemDto, pricingType: CatalogPricingType): number {
    if (pricingType === 'PerKg') {
      if (item.weight === undefined || item.quantity !== undefined) {
        throw new BadRequestException('PerKg services require weight and do not accept quantity');
      }
      return this.positiveUnits(item.weight);
    }
    if (pricingType !== 'Custom') {
      if (item.quantity === undefined || item.weight !== undefined) {
        throw new BadRequestException(
          `${pricingType} services require quantity and do not accept weight`,
        );
      }
      return this.positiveUnits(item.quantity);
    }
    const units = item.quantity ?? item.weight;
    if (units === undefined || (item.quantity !== undefined && item.weight !== undefined)) {
      throw new BadRequestException('Custom services require either quantity or weight');
    }
    return this.positiveUnits(units);
  }

  private positiveUnits(value: number): number {
    if (!Number.isFinite(value) || value <= 0) {
      throw new BadRequestException('Each order item requires a positive quantity or weight');
    }
    return value;
  }

  private catalogPricingType(value: unknown): CatalogPricingType | undefined {
    return typeof value === 'string' && CATALOG_PRICING_TYPES.includes(value as CatalogPricingType)
      ? (value as CatalogPricingType)
      : undefined;
  }

  private totals(
    items: readonly PersistedOrderItem[],
    requestedDiscount: number,
    discountPercentage: number,
    paidAmount: number,
  ): OrderTotals {
    const subtotal = this.money(
      items.reduce((total, item) => total + item.lineTotal - item.tax, 0),
    );
    const percentageDiscount = this.money(subtotal * (discountPercentage / 100));
    const discount = discountPercentage > 0 ? percentageDiscount : this.money(requestedDiscount);
    if (discount > subtotal) {
      throw new BadRequestException('Order discount cannot exceed subtotal');
    }
    const taxableAmount = this.money(subtotal - discount);
    const undiscountedTax = items.reduce((total, item) => total + item.tax, 0);
    const tax = this.money(subtotal === 0 ? 0 : undiscountedTax * (taxableAmount / subtotal));
    const grandTotal = this.money(taxableAmount + tax);
    if (grandTotal < 0) throw new BadRequestException('Grand total cannot be negative');
    if (paidAmount > grandTotal) {
      throw new BadRequestException('Grand total cannot be less than the amount already paid');
    }
    return {
      discount: this.money(discount),
      discountPercentage: this.money(discountPercentage),
      grandTotal,
      items,
      outstandingAmount: this.money(Math.max(grandTotal - paidAmount, 0)),
      paidAmount: this.money(paidAmount),
      subtotal,
      tax: this.money(tax),
    };
  }

  private assertDiscountMode(discount: number | undefined, percentage: number | undefined): void {
    if ((discount ?? 0) > 0 && (percentage ?? 0) > 0) {
      throw new BadRequestException(
        'Use either an absolute discount or a percentage discount, not both',
      );
    }
  }

  private money(value: number): number {
    if (!Number.isFinite(value)) throw new BadRequestException('Money value is invalid');
    return Math.round((value + Number.EPSILON) * 100) / 100;
  }

  private assertRead(scope: OrderScope): void {
    if (
      !['tenant_owner', 'branch_manager', 'cashier', STAFF_ROLE].includes(scope.roleCode) ||
      !scope.permissions.includes('orders:read')
    ) {
      throw new ForbiddenException('Order read permission is required');
    }
  }

  private assertWrite(scope: OrderScope): void {
    if (!WRITE_ROLES.has(scope.roleCode) || !scope.permissions.includes('orders:write')) {
      throw new ForbiddenException('Order write permission is required');
    }
  }

  private assertManage(scope: OrderScope): void {
    if (!MANAGE_ROLES.has(scope.roleCode) || !scope.permissions.includes('orders:write')) {
      throw new ForbiddenException('Order management permission is required');
    }
  }

  private assertTransition(scope: OrderScope, order: OrderRecord): void {
    if (MANAGE_ROLES.has(scope.roleCode) && scope.permissions.includes('orders:write')) {
      return;
    }
    if (
      scope.roleCode === STAFF_ROLE &&
      scope.permissions.includes('orders:write') &&
      order.assignedTo === scope.actorId
    ) {
      return;
    }
    throw new ForbiddenException('Order transition permission is required');
  }

  private notifyStatusChange(scope: OrderScope, order: OrderRecord): void {
    const entry = STATUS_NOTIFICATIONS[order.status];
    if (!entry) return;
    const input: NotifyInput = {
      entityId: order.id,
      entityType: 'Order',
      message: `Order ${order.orderNumber} ${entry.message}.`,
      orderId: order.id,
      title: entry.title,
      type: entry.type,
    };
    this.notify(scope, order.createdBy, input);
    this.notifyOwner(scope, order.createdBy, input);
  }

  /**
   * Fire-and-forget notification delivery: forwards the acting user's own bearer token
   * (same service-to-service pattern used for Branch/Customer/Catalog Service calls), so the
   * created notification lands in the caller's own verified tenant/branch. Never blocks or
   * fails the order operation that triggered it, and never notifies the actor about their own
   * action.
   */
  private notify(scope: OrderScope, recipientId: string | undefined, input: NotifyInput): void {
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
    scope: OrderScope,
    existingRecipientId: string | undefined,
    input: NotifyInput,
  ): void {
    void this.deliverToOwner(scope, existingRecipientId, input);
  }

  private async deliverToOwner(
    scope: OrderScope,
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
    scope: OrderScope,
    recipientId: string,
    input: NotifyInput,
  ): Promise<void> {
    try {
      const baseUrl = this.configService
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
