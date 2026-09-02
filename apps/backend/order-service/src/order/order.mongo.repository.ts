import { Injectable } from '@nestjs/common';
import { InjectConnection, InjectModel } from '@nestjs/mongoose';
import { Connection, FilterQuery, Model, Types } from 'mongoose';

import { OrderPaymentStatus, OrderStatus } from './enums';
import {
  AssignmentMongoose,
  CounterMongoose,
  OrderMongoose,
  StatusHistoryMongoose,
} from './order.schema';
import type {
  CreateOrderRecord,
  OrderAssignmentRecord,
  OrderItemRecord,
  OrderListQuery,
  OrderPage,
  OrderRecord,
  OrderRepository,
  OrderScope,
  OrderStatistics,
  StatusHistoryRecord,
  UpdateOrderRecord,
} from './order.types';

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
      dueDate: document.dueDate as Date | undefined,
      id: identifier(document._id),
      note: document.note as string | undefined,
      orderId: identifier(document.orderId),
      status: document.status as string,
      updatedAt: document.updatedAt as Date,
      version: document.version as number,
    };
  }
}
