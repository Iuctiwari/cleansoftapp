import { Injectable } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model, Types, type AccumulatorOperator } from 'mongoose';

import { OrderPaymentStatus, OrderStatus } from './enums';
import {
  AssignmentMongoose,
  CounterMongoose,
  OrderMongoose,
  StatusHistoryMongoose,
} from './order.schema';
import type {
  CreateOrderRecord,
  DeclineRequestRecord,
  NewOrderNote,
  OrderAssignmentRecord,
  OrderItemRecord,
  OrderListQuery,
  OrderNoteKind,
  OrderNoteRecord,
  OrderPage,
  OrderRecord,
  OrderRepository,
  OrderScope,
  OrderStatistics,
  StatusHistoryRecord,
  TenantOrderSummary,
  UpdateOrderRecord,
  WorkerWorkload,
  WorkloadSummary,
} from './order.types';
import { DeclineConflictError } from './order.types';

/** Statuses in which a worker still holds (and may ask to be taken off) an order. */
const DECLINABLE_STATUSES = [OrderStatus.ASSIGNED, OrderStatus.ACCEPTED, OrderStatus.IN_PROGRESS];
/** Unassigned orders that can go to a worker (Rejected = legacy worker rejections). */
export const ASSIGNABLE_UNASSIGNED_STATUSES = [OrderStatus.RECEIVED, OrderStatus.REJECTED];
const MAX_PENDING_DECLINES = 200;

function escapeRegularExpression(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function identifier(value: unknown): string {
  if (typeof value === 'string') return value;
  if (value instanceof Types.ObjectId) return value.toHexString();
  throw new Error('Persisted identifier is invalid');
}

@Injectable()
export class MongoOrderRepository implements OrderRepository {
  constructor(
    @InjectModel(OrderMongoose.name) private readonly orderModel: Model<OrderMongoose>,
    @InjectModel(CounterMongoose.name) private readonly counterModel: Model<CounterMongoose>,
    @InjectModel(StatusHistoryMongoose.name)
    private readonly historyModel: Model<StatusHistoryMongoose>,
    @InjectModel(AssignmentMongoose.name)
    private readonly assignmentModel: Model<AssignmentMongoose>,
    @InjectConnection() private readonly connection: Connection,
  ) {}

  async create(scope: OrderScope, input: CreateOrderRecord): Promise<OrderRecord> {
    return this.connection.transaction(async (session) => {
      const counter = await this.counterModel
        .findOneAndUpdate(
          { tenantId: scope.tenantId, branchId: scope.branchId, type: 'order' },
          {
            $inc: { sequence: 1 },
            $setOnInsert: {
              branchId: scope.branchId,
              tenantId: new Types.ObjectId(scope.tenantId),
              type: 'order',
            },
          },
          { new: true, runValidators: true, session, setDefaultsOnInsert: true, upsert: true },
        )
        .exec();
      if (!counter) throw new Error('Order counter initialization failed');

      const orderNumber = `ORD-${input.branchCode}-${String(counter.sequence).padStart(6, '0')}`;
      const [order] = await this.orderModel.create(
        [
          {
            assignedTo: input.assignedTo ? new Types.ObjectId(input.assignedTo) : undefined,
            branchId: scope.branchId,
            createdBy: new Types.ObjectId(scope.actorId),
            customerId: new Types.ObjectId(input.customerId),
            customerSnapshot: input.customerSnapshot,
            discount: input.discount,
            discountPercentage: input.discountPercentage,
            expectedDeliveryDate: input.expectedDeliveryDate,
            grandTotal: input.grandTotal,
            items: input.items.map((item) => ({
              ...item,
              itemCategoryId: new Types.ObjectId(item.itemCategoryId),
              serviceId: new Types.ObjectId(item.serviceId),
            })),
            orderNumber,
            outstandingAmount: input.outstandingAmount,
            paidAmount: input.paidAmount,
            paymentStatus: OrderPaymentStatus.UNPAID,
            status: OrderStatus.RECEIVED,
            subtotal: input.subtotal,
            tax: input.tax,
            tenantId: new Types.ObjectId(scope.tenantId),
          },
        ],
        { session },
      );

      await this.historyModel.create(
        [
          {
            branchId: scope.branchId,
            changedBy: new Types.ObjectId(scope.actorId),
            newStatus: OrderStatus.RECEIVED,
            note: 'Order created',
            orderId: order._id,
            previousStatus: OrderStatus.DRAFT,
            tenantId: new Types.ObjectId(scope.tenantId),
            timestamp: new Date(),
          },
        ],
        { session },
      );

      let assignment: OrderAssignmentRecord | undefined;
      if (input.assignedTo) {
        const [assignmentDocument] = await this.assignmentModel.create(
          [
            {
              assignedBy: new Types.ObjectId(scope.actorId),
              assignedTo: new Types.ObjectId(input.assignedTo),
              branchId: scope.branchId,
              orderId: order._id,
              status: 'Assigned',
              tenantId: new Types.ObjectId(scope.tenantId),
            },
          ],
          { session },
        );
        assignment = this.mapAssignment(
          assignmentDocument.toObject() as unknown as Record<string, unknown>,
        );
      }

      return {
        ...this.mapOrder(order.toObject() as unknown as Record<string, unknown>),
        ...(assignment ? { assignment } : {}),
      };
    });
  }

  async findById(scope: OrderScope, id: string, assignedTo?: string): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const scopedFilter = {
      _id: id,
      branchId: scope.branchId,
      tenantId: scope.tenantId,
      ...(assignedTo ? { assignedTo } : {}),
    };
    const [order, assignment] = await Promise.all([
      this.orderModel.findOne(scopedFilter).lean().exec(),
      this.assignmentModel
        .findOne({ branchId: scope.branchId, orderId: id, tenantId: scope.tenantId })
        .lean()
        .exec(),
    ]);
    return order
      ? {
          ...this.mapOrder(order),
          ...(assignment ? { assignment: this.mapAssignment(assignment) } : {}),
        }
      : null;
  }

  async list(scope: OrderScope, query: OrderListQuery): Promise<OrderPage> {
    const filter: FilterQuery<OrderMongoose> = {
      branchId: scope.branchId,
      tenantId: new Types.ObjectId(scope.tenantId),
      ...(query.assignedTo ? { assignedTo: new Types.ObjectId(query.assignedTo) } : {}),
      ...(query.customerId ? { customerId: new Types.ObjectId(query.customerId) } : {}),
      ...(query.paymentStatus ? { paymentStatus: query.paymentStatus } : {}),
      ...(query.status ? { status: query.status } : {}),
    };
    if (query.unassigned) {
      filter.assignedTo = { $exists: false };
      filter.status = query.status ?? { $in: ASSIGNABLE_UNASSIGNED_STATUSES };
    }
    if (query.overdueBefore) {
      filter.expectedDeliveryDate = { $lt: query.overdueBefore };
      filter.status = query.status ?? {
        $nin: [
          OrderStatus.READY,
          OrderStatus.OUT_FOR_DELIVERY,
          OrderStatus.DELIVERED,
          OrderStatus.CANCELLED,
        ],
      };
    }
    if (query.search) {
      const expression = new RegExp(escapeRegularExpression(query.search), 'i');
      filter.$or = [
        { orderNumber: expression },
        { 'customerSnapshot.name': expression },
        { 'customerSnapshot.mobile': expression },
      ];
    }
    const skip = (query.page - 1) * query.limit;
    const sort: Record<string, 1 | -1> = {
      [query.sortBy]: query.sortDirection,
      _id: query.sortDirection,
    };
    const [orders, total] = await Promise.all([
      this.orderModel.find(filter).sort(sort).skip(skip).limit(query.limit).lean().exec(),
      this.orderModel.countDocuments(filter).exec(),
    ]);
    return {
      items: orders.map((order) => this.mapOrder(order)),
      limit: query.limit,
      page: query.page,
      total,
      totalPages: Math.ceil(total / query.limit),
    };
  }

  async getSummaryForTenant(tenantId: string): Promise<TenantOrderSummary> {
    const tenantObjectId = new Types.ObjectId(tenantId);
    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);

    const [totalOrders, ordersThisMonth, lastOrder, outstandingResult] = await Promise.all([
      this.orderModel.countDocuments({ tenantId: tenantObjectId }).exec(),
      this.orderModel
        .countDocuments({ tenantId: tenantObjectId, createdAt: { $gte: monthStart } })
        .exec(),
      this.orderModel
        .findOne({ tenantId: tenantObjectId })
        .sort({ createdAt: -1 })
        .select('createdAt')
        .lean<{ createdAt: Date } | null>()
        .exec(),
      this.orderModel
        .aggregate<{
          outstandingTotal: number;
        }>([{ $match: { tenantId: tenantObjectId } }, { $group: { _id: null, outstandingTotal: { $sum: '$outstandingAmount' } } }])
        .exec(),
    ]);

    return {
      lastOrderDate: lastOrder?.createdAt ? lastOrder.createdAt.toISOString() : null,
      ordersThisMonth,
      outstandingMinor: Math.round((outstandingResult[0]?.outstandingTotal ?? 0) * 100),
      totalOrders,
    };
  }

  async statistics(
    scope: OrderScope,
    filters: { readonly assignedTo?: string; readonly customerId?: string },
  ): Promise<OrderStatistics> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    const [result] = await this.orderModel
      .aggregate<{
        totals: Array<{
          totalOrders: number;
          todayOrders: number;
          yesterdayOrders: number;
          outstandingTotal: number;
        }>;
        outstandingCustomers: Array<{ count: number }>;
        statuses: Array<{ _id: string; count: number }>;
      }>([
        {
          $match: {
            tenantId: new Types.ObjectId(scope.tenantId),
            branchId: scope.branchId,
            ...(filters.assignedTo ? { assignedTo: new Types.ObjectId(filters.assignedTo) } : {}),
            ...(filters.customerId ? { customerId: new Types.ObjectId(filters.customerId) } : {}),
          },
        },
        {
          $facet: {
            totals: [
              {
                $group: {
                  _id: null,
                  totalOrders: { $sum: 1 },
                  todayOrders: {
                    $sum: {
                      $cond: [
                        {
                          $and: [
                            { $gte: ['$createdAt', today] },
                            { $lt: ['$createdAt', tomorrow] },
                          ],
                        },
                        1,
                        0,
                      ],
                    },
                  },
                  yesterdayOrders: {
                    $sum: {
                      $cond: [
                        {
                          $and: [
                            { $gte: ['$createdAt', yesterday] },
                            { $lt: ['$createdAt', today] },
                          ],
                        },
                        1,
                        0,
                      ],
                    },
                  },
                  outstandingTotal: {
                    $sum: {
                      $cond: [
                        { $in: ['$paymentStatus', ['Unpaid', 'PartiallyPaid']] },
                        '$outstandingAmount',
                        0,
                      ],
                    },
                  },
                },
              },
            ],
            outstandingCustomers: [
              { $match: { paymentStatus: { $in: ['Unpaid', 'PartiallyPaid'] } } },
              { $group: { _id: '$customerId' } },
              { $count: 'count' },
            ],
            statuses: [{ $group: { _id: '$status', count: { $sum: 1 } } }, { $sort: { _id: 1 } }],
          },
        },
      ])
      .exec();
    const totals = result?.totals[0];
    return {
      totalOrders: totals?.totalOrders ?? 0,
      todayOrders: totals?.todayOrders ?? 0,
      yesterdayOrders: totals?.yesterdayOrders ?? 0,
      outstandingTotal: totals?.outstandingTotal ?? 0,
      outstandingCustomerCount: result?.outstandingCustomers[0]?.count ?? 0,
      statusBreakdown: Object.fromEntries(
        (result?.statuses ?? []).map((item) => [item._id, item.count]),
      ),
    };
  }

  async update(
    scope: OrderScope,
    id: string,
    status: OrderStatus,
    input: UpdateOrderRecord,
  ): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const order = await this.orderModel
      .findOneAndUpdate(
        { _id: id, branchId: scope.branchId, status, tenantId: scope.tenantId },
        {
          $set: {
            discount: input.discount,
            discountPercentage: input.discountPercentage,
            expectedDeliveryDate: input.expectedDeliveryDate,
            grandTotal: input.grandTotal,
            items: input.items.map((item) => ({
              ...item,
              itemCategoryId: new Types.ObjectId(item.itemCategoryId),
              serviceId: new Types.ObjectId(item.serviceId),
            })),
            outstandingAmount: input.outstandingAmount,
            paidAmount: input.paidAmount,
            subtotal: input.subtotal,
            tax: input.tax,
          },
        },
        { new: true, runValidators: true },
      )
      .lean()
      .exec();
    return order ? this.mapOrder(order) : null;
  }

  async transition(
    scope: OrderScope,
    id: string,
    previousStatus: OrderStatus,
    newStatus: OrderStatus,
    note?: string,
    cancelReason?: string,
  ): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    return this.connection.transaction(async (session) => {
      const order = await this.orderModel
        .findOneAndUpdate(
          { _id: id, branchId: scope.branchId, status: previousStatus, tenantId: scope.tenantId },
          {
            $set: {
              ...(cancelReason ? { cancelReason } : {}),
              ...(newStatus === OrderStatus.DELIVERED ? { deliveryDate: new Date() } : {}),
              status: newStatus,
              updatedAt: new Date(),
            },
          },
          { new: true, runValidators: true, session },
        )
        .lean()
        .exec();
      if (!order) return null;
      await this.historyModel.create(
        [
          {
            branchId: scope.branchId,
            changedBy: new Types.ObjectId(scope.actorId),
            newStatus,
            note,
            orderId: new Types.ObjectId(id),
            previousStatus,
            tenantId: new Types.ObjectId(scope.tenantId),
            timestamp: new Date(),
          },
        ],
        { session },
      );
      return this.mapOrder(order);
    });
  }

  async applyPaymentProjection(
    scope: OrderScope,
    id: string,
    paymentId: string,
    amount: number,
  ): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id) || !Types.ObjectId.isValid(paymentId)) return null;
    const paymentObjectId = new Types.ObjectId(paymentId);
    const order = await this.orderModel
      .findOneAndUpdate(
        {
          _id: id,
          branchId: scope.branchId,
          tenantId: scope.tenantId,
          paymentProjectionIds: { $ne: paymentObjectId },
          $expr: { $lte: [{ $add: ['$paidAmount', amount] }, '$grandTotal'] },
        },
        [
          {
            $set: {
              paidAmount: { $add: ['$paidAmount', amount] },
              outstandingAmount: {
                $max: [{ $subtract: ['$grandTotal', { $add: ['$paidAmount', amount] }] }, 0],
              },
              paymentStatus: {
                $cond: [
                  { $gte: [{ $add: ['$paidAmount', amount] }, '$grandTotal'] },
                  OrderPaymentStatus.PAID,
                  OrderPaymentStatus.PARTIALLY_PAID,
                ],
              },
              paymentProjectionIds: {
                $concatArrays: [{ $ifNull: ['$paymentProjectionIds', []] }, [paymentObjectId]],
              },
            },
          },
        ],
        { new: true },
      )
      .lean()
      .exec();
    if (order) return this.mapOrder(order);

    const existing = await this.orderModel
      .findOne({ _id: id, branchId: scope.branchId, tenantId: scope.tenantId })
      .select('+paymentProjectionIds')
      .lean()
      .exec();
    if (existing?.paymentProjectionIds?.some((value) => String(value) === paymentId)) {
      return this.mapOrder(existing);
    }
    return null;
  }

  async assign(
    scope: OrderScope,
    id: string,
    assignedTo: string,
    dueDate?: Date,
    note?: string,
  ): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    return this.connection.transaction(async (session) => {
      const order = await this.orderModel
        .findOneAndUpdate(
          {
            _id: id,
            assignedTo: { $ne: new Types.ObjectId(assignedTo) },
            branchId: scope.branchId,
            status: { $nin: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
            tenantId: scope.tenantId,
          },
          {
            $set: {
              assignedTo: new Types.ObjectId(assignedTo),
              status: OrderStatus.ASSIGNED,
              updatedAt: new Date(),
            },
          },
          { new: true, runValidators: true, session },
        )
        .lean()
        .exec();
      if (!order) return null;
      const assignment = await this.assignmentModel
        .findOneAndUpdate(
          { branchId: scope.branchId, orderId: id, tenantId: scope.tenantId },
          {
            $set: {
              assignedTo: new Types.ObjectId(assignedTo),
              dueDate,
              note,
              status: 'Assigned',
            },
            $unset: { declineRequest: 1 },
            $setOnInsert: { assignedBy: new Types.ObjectId(scope.actorId) },
          },
          {
            new: true,
            runValidators: true,
            session,
            setDefaultsOnInsert: true,
            upsert: true,
          },
        )
        .lean()
        .exec();
      if (!assignment) throw new Error('Order assignment persistence failed');

      if (typeof this.historyModel?.create === 'function') {
        await this.historyModel.create(
          [
            {
              branchId: scope.branchId,
              changedBy: new Types.ObjectId(scope.actorId),
              newStatus: OrderStatus.ASSIGNED,
              note,
              orderId: new Types.ObjectId(id),
              previousStatus: OrderStatus.RECEIVED,
              tenantId: new Types.ObjectId(scope.tenantId),
              timestamp: new Date(),
            },
          ],
          { session },
        );
      }

      return { ...this.mapOrder(order), assignment: this.mapAssignment(assignment) };
    });
  }

  async acceptAssignment(scope: OrderScope, id: string): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    return this.connection.transaction(async (session) => {
      const order = await this.orderModel
        .findOneAndUpdate(
          {
            _id: id,
            branchId: scope.branchId,
            status: { $nin: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
            tenantId: scope.tenantId,
          },
          { $set: { status: OrderStatus.ACCEPTED, updatedAt: new Date() } },
          { new: true, runValidators: true, session },
        )
        .lean()
        .exec();
      if (!order) return null;

      const assignment = await this.assignmentModel
        .findOneAndUpdate(
          { branchId: scope.branchId, orderId: id, tenantId: scope.tenantId },
          { $set: { status: 'Accepted' } },
          { new: true, runValidators: true, session },
        )
        .lean()
        .exec();
      if (!assignment) return null;

      await this.historyModel.create(
        [
          {
            branchId: scope.branchId,
            changedBy: new Types.ObjectId(scope.actorId),
            newStatus: OrderStatus.ACCEPTED,
            note: 'Assignment accepted by worker',
            orderId: new Types.ObjectId(id),
            previousStatus: OrderStatus.ASSIGNED,
            tenantId: new Types.ObjectId(scope.tenantId),
            timestamp: new Date(),
          },
        ],
        { session },
      );

      return { ...this.mapOrder(order), assignment: this.mapAssignment(assignment) };
    });
  }

  async rejectAssignment(
    scope: OrderScope,
    id: string,
    reason?: string,
  ): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    return this.connection.transaction(async (session) => {
      const order = await this.orderModel
        .findOneAndUpdate(
          {
            _id: id,
            branchId: scope.branchId,
            status: { $nin: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
            tenantId: scope.tenantId,
          },
          {
            $unset: { assignedTo: 1 },
            $set: { status: OrderStatus.REJECTED, updatedAt: new Date() },
          },
          { new: true, runValidators: true, session },
        )
        .lean()
        .exec();
      if (!order) return null;

      const assignment = await this.assignmentModel
        .findOneAndUpdate(
          { branchId: scope.branchId, orderId: id, tenantId: scope.tenantId },
          { $set: { status: 'Rejected' } },
          { new: true, runValidators: true, session },
        )
        .lean()
        .exec();

      await this.historyModel.create(
        [
          {
            branchId: scope.branchId,
            changedBy: new Types.ObjectId(scope.actorId),
            newStatus: OrderStatus.REJECTED,
            note: reason?.trim()
              ? `Assignment rejected: ${reason.trim()}`
              : 'Assignment rejected by worker',
            orderId: new Types.ObjectId(id),
            previousStatus: OrderStatus.ASSIGNED,
            tenantId: new Types.ObjectId(scope.tenantId),
            timestamp: new Date(),
          },
        ],
        { session },
      );

      return {
        ...this.mapOrder(order),
        ...(assignment ? { assignment: this.mapAssignment(assignment) } : {}),
      };
    });
  }

  async requestDecline(
    scope: OrderScope,
    id: string,
    workerId: string,
    reason: string,
  ): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const workerObjectId = new Types.ObjectId(workerId);
    const order = await this.orderModel
      .findOne({
        _id: id,
        assignedTo: workerObjectId,
        branchId: scope.branchId,
        status: { $in: DECLINABLE_STATUSES },
        tenantId: scope.tenantId,
      })
      .lean()
      .exec();
    if (!order) return null;
    const assignment = await this.assignmentModel
      .findOneAndUpdate(
        {
          assignedTo: workerObjectId,
          branchId: scope.branchId,
          'declineRequest.status': { $ne: 'Pending' },
          orderId: id,
          tenantId: scope.tenantId,
        },
        {
          $set: {
            declineRequest: {
              reason,
              requestedAt: new Date(),
              requestedBy: workerObjectId,
              status: 'Pending',
            },
          },
        },
        { new: true, runValidators: true },
      )
      .lean()
      .exec();
    if (!assignment) return null;
    return { ...this.mapOrder(order), assignment: this.mapAssignment(assignment) };
  }

  async resolveDecline(
    scope: OrderScope,
    id: string,
    approve: boolean,
    responseNote?: string,
  ): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    return this.connection.transaction(async (session) => {
      const assignment = await this.assignmentModel
        .findOneAndUpdate(
          {
            branchId: scope.branchId,
            'declineRequest.status': 'Pending',
            orderId: id,
            tenantId: scope.tenantId,
          },
          {
            $set: {
              'declineRequest.resolvedAt': new Date(),
              'declineRequest.resolvedBy': new Types.ObjectId(scope.actorId),
              'declineRequest.status': approve ? 'Approved' : 'Denied',
              ...(responseNote ? { 'declineRequest.responseNote': responseNote } : {}),
              ...(approve ? { status: 'Declined' } : {}),
            },
          },
          { new: true, runValidators: true, session },
        )
        .lean()
        .exec();
      if (!assignment) return null;

      if (approve) {
        const previous = await this.orderModel
          .findOneAndUpdate(
            {
              _id: id,
              assignedTo: assignment.assignedTo,
              branchId: scope.branchId,
              status: { $in: DECLINABLE_STATUSES },
              tenantId: scope.tenantId,
            },
            {
              $set: { status: OrderStatus.RECEIVED, updatedAt: new Date() },
              $unset: { assignedTo: 1 },
            },
            { new: false, runValidators: true, session },
          )
          .lean()
          .exec();
        // The order moved on (reassigned or finished) since the request: roll back.
        if (!previous) throw new DeclineConflictError();

        const reason = assignment.declineRequest?.reason;
        await this.historyModel.create(
          [
            {
              branchId: scope.branchId,
              changedBy: new Types.ObjectId(scope.actorId),
              newStatus: OrderStatus.RECEIVED,
              note: reason ? `Decline request approved: ${reason}` : 'Decline request approved',
              orderId: new Types.ObjectId(id),
              previousStatus: previous.status,
              tenantId: new Types.ObjectId(scope.tenantId),
              timestamp: new Date(),
            },
          ],
          { session },
        );
      }

      const order = await this.orderModel
        .findOne({ _id: id, branchId: scope.branchId, tenantId: scope.tenantId })
        .session(session)
        .lean()
        .exec();
      return order ? { ...this.mapOrder(order), assignment: this.mapAssignment(assignment) } : null;
    });
  }

  async listPendingDeclines(scope: OrderScope): Promise<readonly OrderRecord[]> {
    const assignments = await this.assignmentModel
      .find({
        branchId: scope.branchId,
        'declineRequest.status': 'Pending',
        tenantId: scope.tenantId,
      })
      .sort({ 'declineRequest.requestedAt': 1 })
      .limit(MAX_PENDING_DECLINES)
      .lean()
      .exec();
    if (assignments.length === 0) return [];
    const orders = await this.orderModel
      .find({
        _id: { $in: assignments.map((assignment) => assignment.orderId) },
        branchId: scope.branchId,
        tenantId: scope.tenantId,
      })
      .lean()
      .exec();
    const byId = new Map(orders.map((order) => [identifier(order._id), order]));
    return assignments.flatMap((assignment) => {
      const order = byId.get(identifier(assignment.orderId));
      return order ? [{ ...this.mapOrder(order), assignment: this.mapAssignment(assignment) }] : [];
    });
  }

  async addNote(scope: OrderScope, id: string, note: NewOrderNote): Promise<OrderRecord | null> {
    if (!Types.ObjectId.isValid(id)) return null;
    const order = await this.orderModel
      .findOneAndUpdate(
        { _id: id, branchId: scope.branchId, tenantId: scope.tenantId },
        {
          $push: {
            notes: {
              _id: new Types.ObjectId(note.id),
              authorId: new Types.ObjectId(note.authorId),
              authorRole: note.authorRole,
              createdAt: note.createdAt,
              kind: note.kind,
              text: note.text,
              ...(note.itemId ? { itemId: new Types.ObjectId(note.itemId) } : {}),
            },
          },
        },
        { new: true, runValidators: true },
      )
      .lean()
      .exec();
    return order ? this.mapOrder(order) : null;
  }

  async workload(scope: OrderScope, now: Date): Promise<WorkloadSummary> {
    const tenantId = new Types.ObjectId(scope.tenantId);
    const startOfToday = new Date(now);
    startOfToday.setHours(0, 0, 0, 0);
    const finished = [OrderStatus.READY, OrderStatus.OUT_FOR_DELIVERY, OrderStatus.DELIVERED];
    const count = (condition: unknown): AccumulatorOperator => ({
      $sum: { $cond: [condition, 1, 0] },
    });
    const isStatus = (status: OrderStatus): unknown => ({ $eq: ['$status', status] });

    const [rows, unassigned, declines] = await Promise.all([
      this.orderModel
        .aggregate<{
          _id: Types.ObjectId;
          assigned: number;
          accepted: number;
          inProgress: number;
          ready: number;
          outForDelivery: number;
          deliveredToday: number;
          deliveredTotal: number;
          overdue: number;
          damageReports: number;
        }>([
          {
            $match: {
              assignedTo: { $exists: true, $ne: null },
              branchId: scope.branchId,
              status: { $ne: OrderStatus.CANCELLED },
              tenantId,
            },
          },
          {
            $group: {
              _id: '$assignedTo',
              accepted: count(isStatus(OrderStatus.ACCEPTED)),
              assigned: count(isStatus(OrderStatus.ASSIGNED)),
              damageReports: {
                $sum: {
                  $size: {
                    $filter: {
                      as: 'note',
                      cond: { $eq: ['$$note.kind', 'Damage'] },
                      input: { $ifNull: ['$notes', []] },
                    },
                  },
                },
              },
              deliveredToday: count({
                $and: [
                  isStatus(OrderStatus.DELIVERED),
                  { $gte: [{ $ifNull: ['$deliveryDate', '$updatedAt'] }, startOfToday] },
                ],
              }),
              deliveredTotal: count(isStatus(OrderStatus.DELIVERED)),
              inProgress: count(isStatus(OrderStatus.IN_PROGRESS)),
              outForDelivery: count(isStatus(OrderStatus.OUT_FOR_DELIVERY)),
              overdue: count({
                $and: [
                  { $not: [{ $in: ['$status', finished] }] },
                  { $ne: [{ $ifNull: ['$expectedDeliveryDate', null] }, null] },
                  { $lt: ['$expectedDeliveryDate', now] },
                ],
              }),
              ready: count(isStatus(OrderStatus.READY)),
            },
          },
        ])
        .exec(),
      this.orderModel
        .countDocuments({
          assignedTo: { $exists: false },
          branchId: scope.branchId,
          status: { $in: ASSIGNABLE_UNASSIGNED_STATUSES },
          tenantId,
        })
        .exec(),
      this.assignmentModel
        .aggregate<{ _id: Types.ObjectId; count: number }>([
          {
            $match: {
              branchId: scope.branchId,
              'declineRequest.status': 'Pending',
              tenantId,
            },
          },
          { $group: { _id: '$assignedTo', count: { $sum: 1 } } },
        ])
        .exec(),
    ]);

    const pendingByWorker = new Map(declines.map((row) => [identifier(row._id), row.count]));
    const workers = rows.map(
      (row): WorkerWorkload => ({
        accepted: row.accepted,
        assigned: row.assigned,
        damageReports: row.damageReports,
        deliveredToday: row.deliveredToday,
        deliveredTotal: row.deliveredTotal,
        inProgress: row.inProgress,
        open: row.assigned + row.accepted + row.inProgress,
        outForDelivery: row.outForDelivery,
        overdue: row.overdue,
        pendingDeclineRequests: pendingByWorker.get(identifier(row._id)) ?? 0,
        ready: row.ready,
        workerId: identifier(row._id),
      }),
    );
    workers.sort((a, b) => b.open - a.open || a.workerId.localeCompare(b.workerId));
    return {
      generatedAt: now,
      pendingDeclineRequests: declines.reduce((total, row) => total + row.count, 0),
      unassigned,
      workers,
    };
  }

  async openCounts(
    scope: OrderScope,
    workerIds: readonly string[],
  ): Promise<Readonly<Record<string, number>>> {
    if (workerIds.length === 0) return {};
    const rows = await this.orderModel
      .aggregate<{ _id: Types.ObjectId; count: number }>([
        {
          $match: {
            assignedTo: { $in: workerIds.map((workerId) => new Types.ObjectId(workerId)) },
            branchId: scope.branchId,
            status: { $in: DECLINABLE_STATUSES },
            tenantId: new Types.ObjectId(scope.tenantId),
          },
        },
        { $group: { _id: '$assignedTo', count: { $sum: 1 } } },
      ])
      .exec();
    return Object.fromEntries(rows.map((row) => [identifier(row._id), row.count]));
  }

  async history(scope: OrderScope, orderId: string): Promise<readonly StatusHistoryRecord[]> {
    if (!Types.ObjectId.isValid(orderId)) return [];
    const records = await this.historyModel
      .find({ branchId: scope.branchId, orderId, tenantId: scope.tenantId })
      .sort({ timestamp: 1, _id: 1 })
      .lean()
      .exec();
    return records.map((record) => ({
      changedBy: identifier(record.changedBy),
      id: identifier(record._id),
      newStatus: record.newStatus,
      note: record.note,
      orderId: identifier(record.orderId),
      previousStatus: record.previousStatus,
      timestamp: record.timestamp,
    }));
  }

  private mapOrder(document: Record<string, unknown>): OrderRecord {
    const items = (document.items as readonly Record<string, unknown>[]).map(
      (item): OrderItemRecord => ({
        discount: item.discount as number,
        id: identifier(item._id),
        itemCategoryId: identifier(item.itemCategoryId),
        itemCategorySnapshot: item.itemCategorySnapshot as Record<string, unknown>,
        lineTotal: item.lineTotal as number,
        notes: item.notes as string | undefined,
        processingStatus: item.processingStatus as string | undefined,
        quantity: item.quantity as number | undefined,
        serviceId: identifier(item.serviceId),
        serviceSnapshot: item.serviceSnapshot as Record<string, unknown>,
        tax: item.tax as number,
        unitPrice: item.unitPrice as number,
        weight: item.weight as number | undefined,
      }),
    );
    return {
      assignedTo: document.assignedTo ? identifier(document.assignedTo) : undefined,
      branchId: document.branchId as string,
      cancelReason: document.cancelReason as string | undefined,
      createdAt: document.createdAt as Date,
      createdBy: identifier(document.createdBy),
      customerId: identifier(document.customerId),
      customerSnapshot: document.customerSnapshot as Record<string, unknown>,
      deliveryDate: document.deliveryDate as Date | undefined,
      discount: document.discount as number,
      discountPercentage: (document.discountPercentage as number | undefined) ?? 0,
      expectedDeliveryDate: document.expectedDeliveryDate as Date | undefined,
      grandTotal: document.grandTotal as number,
      id: identifier(document._id),
      items,
      notes: ((document.notes as readonly Record<string, unknown>[] | undefined) ?? []).map(
        (note): OrderNoteRecord => ({
          authorId: identifier(note.authorId),
          authorRole: note.authorRole as string,
          createdAt: note.createdAt as Date,
          id: identifier(note._id),
          ...(note.itemId ? { itemId: identifier(note.itemId) } : {}),
          kind: note.kind as OrderNoteKind,
          text: note.text as string,
        }),
      ),
      orderNumber: document.orderNumber as string,
      outstandingAmount: document.outstandingAmount as number,
      paidAmount: document.paidAmount as number,
      paymentStatus: document.paymentStatus as OrderPaymentStatus,
      status: document.status as OrderStatus,
      subtotal: document.subtotal as number,
      tax: document.tax as number,
      tenantId: identifier(document.tenantId),
      updatedAt: document.updatedAt as Date,
      version: document.version as number,
    };
  }

  private mapAssignment(document: Record<string, unknown>): OrderAssignmentRecord {
    return {
      assignedBy: identifier(document.assignedBy),
      assignedTo: identifier(document.assignedTo),
      createdAt: document.createdAt as Date,
      ...(document.declineRequest
        ? { declineRequest: this.mapDecline(document.declineRequest) }
        : {}),
      dueDate: document.dueDate as Date | undefined,
      id: identifier(document._id),
      note: document.note as string | undefined,
      orderId: identifier(document.orderId),
      status: document.status as string,
      updatedAt: document.updatedAt as Date,
      version: document.version as number,
    };
  }

  private mapDecline(value: unknown): DeclineRequestRecord {
    const request = value as Record<string, unknown>;
    return {
      reason: request.reason as string,
      requestedAt: request.requestedAt as Date,
      requestedBy: identifier(request.requestedBy),
      ...(request.resolvedAt ? { resolvedAt: request.resolvedAt as Date } : {}),
      ...(request.resolvedBy ? { resolvedBy: identifier(request.resolvedBy) } : {}),
      ...(request.responseNote ? { responseNote: request.responseNote as string } : {}),
      status: request.status as DeclineRequestRecord['status'],
    };
  }
}
