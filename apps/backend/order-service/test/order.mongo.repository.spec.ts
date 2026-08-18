import { Types, type ClientSession, type Connection, type Model } from 'mongoose';

import { OrderPaymentStatus, OrderStatus } from '../src/order/enums';
import { MongoOrderRepository } from '../src/order/order.mongo.repository';
import type {
  AssignmentMongoose,
  CounterMongoose,
  OrderMongoose,
  StatusHistoryMongoose,
} from '../src/order/order.schema';
import type { OrderScope } from '../src/order/order.types';

const ACTOR_ID = '64f0c18f7c4d2f0012ab34aa';
const TENANT_ID = '64f0c18f7c4d2f0012ab34bb';
const ORDER_ID = '64f0c18f7c4d2f0012ab34cc';
const WORKER_ID = '64f0c18f7c4d2f0012ab34dd';

const scope: OrderScope = {
  actorId: ACTOR_ID,
  authorization: 'Bearer token',
  branchId: 'branch-a',
  permissions: ['orders:read'],
  roleCode: 'branch_manager',
  tenantId: TENANT_ID,
};

function persistedOrder(
  status: OrderStatus,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    _id: new Types.ObjectId(ORDER_ID),
    branchId: scope.branchId,
    createdAt: new Date('2026-08-14T10:00:00.000Z'),
    createdBy: new Types.ObjectId(ACTOR_ID),
    customerId: new Types.ObjectId('64f0c18f7c4d2f0012ab34ee'),
    customerSnapshot: { name: 'John' },
    discount: 0,
    grandTotal: 100,
    items: [
      {
        _id: new Types.ObjectId(),
        discount: 0,
        itemCategoryId: new Types.ObjectId(),
        itemCategorySnapshot: { name: 'Shirt' },
        lineTotal: 100,
        quantity: 1,
        serviceId: new Types.ObjectId(),
        serviceSnapshot: { name: 'Wash' },
        tax: 0,
        unitPrice: 100,
      },
    ],
    orderNumber: 'ORD-MAIN-000123',
    outstandingAmount: 100,
    paidAmount: 0,
    paymentStatus: OrderPaymentStatus.UNPAID,
    status,
    subtotal: 100,
    tax: 0,
    tenantId: new Types.ObjectId(TENANT_ID),
    updatedAt: new Date('2026-08-14T10:00:00.000Z'),
    version: 0,
    ...overrides,
  };
}

describe('MongoOrderRepository scoped list/details queries', () => {
  it('generates the padded order number and initial history inside one transaction', async () => {
    const session = {} as ClientSession;
    const transaction = jest.fn(
      async (operation: (activeSession: ClientSession) => Promise<unknown>): Promise<unknown> =>
        operation(session),
    );
    const counterExec = jest.fn().mockResolvedValue({ sequence: 123 });
    const counterFindOneAndUpdate = jest.fn().mockReturnValue({ exec: counterExec });
    const orderCreate = jest.fn(
      (documents: readonly Record<string, unknown>[]): Promise<readonly unknown[]> => {
        const input = documents[0] ?? {};
        const items = (input.items as readonly Record<string, unknown>[]).map((item) => ({
          ...item,
          _id: new Types.ObjectId(),
        }));
        const persisted = {
          ...input,
          _id: new Types.ObjectId(ORDER_ID),
          createdAt: new Date('2026-08-14T10:00:00.000Z'),
          items,
          updatedAt: new Date('2026-08-14T10:00:00.000Z'),
          version: 0,
        };
        return Promise.resolve([{ _id: persisted._id, toObject: () => persisted }]);
      },
    );
    const historyCreate = jest.fn().mockResolvedValue([]);
    const repository = new MongoOrderRepository(
      { create: orderCreate } as unknown as Model<OrderMongoose>,
      { findOneAndUpdate: counterFindOneAndUpdate } as unknown as Model<CounterMongoose>,
      { create: historyCreate } as unknown as Model<StatusHistoryMongoose>,
      {} as Model<AssignmentMongoose>,
      { transaction } as unknown as Connection,
    );

    const result = await repository.create(scope, {
      branchCode: 'MAIN',
      customerId: '64f0c18f7c4d2f0012ab34dd',
      customerSnapshot: { name: 'John', mobile: '9000000000' },
      discount: 10,
      discountPercentage: 0,
      grandTotal: 90,
      items: [
        {
          discount: 0,
          itemCategoryId: '64f0c18f7c4d2f0012ab34ee',
          itemCategorySnapshot: { name: 'Shirt' },
          lineTotal: 100,
          quantity: 1,
          serviceId: '64f0c18f7c4d2f0012ab34ff',
          serviceSnapshot: { name: 'Wash' },
          tax: 0,
          unitPrice: 100,
        },
      ],
      outstandingAmount: 90,
      paidAmount: 0,
      subtotal: 100,
      tax: 0,
    });

    expect(transaction.mock.calls).toHaveLength(1);
    expect(counterFindOneAndUpdate.mock.calls[0]).toEqual([
      { branchId: scope.branchId, tenantId: scope.tenantId, type: 'order' },
      expect.objectContaining({ $inc: { sequence: 1 } }),
      expect.objectContaining({ session, upsert: true }),
    ]);
    expect(result).toMatchObject({
      orderNumber: 'ORD-MAIN-000123',
      paymentStatus: OrderPaymentStatus.UNPAID,
      status: OrderStatus.RECEIVED,
    });
    const historyCalls = historyCreate.mock.calls as unknown as readonly (readonly [
      readonly Record<string, unknown>[],
      { readonly session: ClientSession },
    ])[];
    expect(historyCalls[0]?.[0][0]).toEqual(
      expect.objectContaining({
        newStatus: OrderStatus.RECEIVED,
        previousStatus: OrderStatus.DRAFT,
      }),
    );
    expect(historyCalls[0]?.[1]).toEqual({ session });
  });

  it('searches order number, customer name, and customer mobile in MongoDB', async () => {
    const ordersExec = jest.fn().mockResolvedValue([]);
    const lean = jest.fn().mockReturnValue({ exec: ordersExec });
    const limit = jest.fn().mockReturnValue({ lean });
    const skip = jest.fn().mockReturnValue({ limit });
    const sort = jest.fn().mockReturnValue({ skip });
    const find = jest.fn().mockReturnValue({ sort });
    const countExec = jest.fn().mockResolvedValue(21);
    const countDocuments = jest.fn().mockReturnValue({ exec: countExec });
    const repository = new MongoOrderRepository(
      { countDocuments, find } as unknown as Model<OrderMongoose>,
      {} as Model<CounterMongoose>,
      {} as Model<StatusHistoryMongoose>,
      {} as Model<AssignmentMongoose>,
      {} as Connection,
    );

    const result = await repository.list(scope, {
      limit: 10,
      page: 2,
      paymentStatus: OrderPaymentStatus.UNPAID,
      search: 'John +91',
      sortBy: 'createdAt',
      sortDirection: -1,
      status: OrderStatus.RECEIVED,
    });

    const findCalls = find.mock.calls as unknown as readonly (readonly [Record<string, unknown>])[];
    const filter = findCalls[0]?.[0] ?? {};
    const alternatives = filter.$or as readonly Record<string, RegExp>[];
    expect(filter.branchId).toBe(scope.branchId);
    expect(String(filter.tenantId)).toBe(scope.tenantId);
    expect(alternatives.map((entry) => Object.keys(entry)[0])).toEqual([
      'orderNumber',
      'customerSnapshot.name',
      'customerSnapshot.mobile',
    ]);
    expect(alternatives.every((entry) => Object.values(entry)[0]?.source === 'John \\+91')).toBe(
      true,
    );
    expect(skip.mock.calls).toContainEqual([10]);
    expect(limit.mock.calls).toContainEqual([10]);
    expect(sort.mock.calls).toContainEqual([{ _id: -1, createdAt: -1 }]);
    expect(result).toEqual({ items: [], limit: 10, page: 2, total: 21, totalPages: 3 });
  });

  it('includes tenant, branch, and staff assignment in the details lookup itself', async () => {
    const orderExec = jest.fn().mockResolvedValue(null);
    const orderLean = jest.fn().mockReturnValue({ exec: orderExec });
    const orderFindOne = jest.fn().mockReturnValue({ lean: orderLean });
    const assignmentExec = jest.fn().mockResolvedValue(null);
    const assignmentLean = jest.fn().mockReturnValue({ exec: assignmentExec });
    const assignmentFindOne = jest.fn().mockReturnValue({ lean: assignmentLean });
    const repository = new MongoOrderRepository(
      { findOne: orderFindOne } as unknown as Model<OrderMongoose>,
      {} as Model<CounterMongoose>,
      {} as Model<StatusHistoryMongoose>,
      { findOne: assignmentFindOne } as unknown as Model<AssignmentMongoose>,
      {} as Connection,
    );

    await expect(repository.findById(scope, ORDER_ID, ACTOR_ID)).resolves.toBeNull();

    const orderFindCalls = orderFindOne.mock.calls as unknown as readonly (readonly [
      Record<string, unknown>,
    ])[];
    const assignmentFindCalls = assignmentFindOne.mock.calls as unknown as readonly (readonly [
      Record<string, unknown>,
    ])[];
    expect(orderFindCalls[0]?.[0]).toEqual({
      _id: ORDER_ID,
      assignedTo: ACTOR_ID,
      branchId: scope.branchId,
      tenantId: scope.tenantId,
    });
    expect(assignmentFindCalls[0]?.[0]).toEqual({
      branchId: scope.branchId,
      orderId: ORDER_ID,
      tenantId: scope.tenantId,
    });
  });

  it('stores an assignment atomically with scoped duplicate and terminal-state protection', async () => {
    const session = {} as ClientSession;
    const transaction = jest.fn(
      async (operation: (activeSession: ClientSession) => Promise<unknown>): Promise<unknown> =>
        operation(session),
    );
    const orderExec = jest
      .fn()
      .mockResolvedValue(
        persistedOrder(OrderStatus.RECEIVED, { assignedTo: new Types.ObjectId(WORKER_ID) }),
      );
    const orderLean = jest.fn().mockReturnValue({ exec: orderExec });
    const orderFindOneAndUpdate = jest.fn().mockReturnValue({ lean: orderLean });
    const assignmentRecord = {
      _id: new Types.ObjectId(),
      assignedBy: new Types.ObjectId(ACTOR_ID),
      assignedTo: new Types.ObjectId(WORKER_ID),
      createdAt: new Date('2026-08-14T10:00:00.000Z'),
      orderId: new Types.ObjectId(ORDER_ID),
      status: 'Assigned',
      updatedAt: new Date('2026-08-14T10:00:00.000Z'),
      version: 0,
    };
    const assignmentExec = jest.fn().mockResolvedValue(assignmentRecord);
    const assignmentLean = jest.fn().mockReturnValue({ exec: assignmentExec });
    const assignmentFindOneAndUpdate = jest.fn().mockReturnValue({ lean: assignmentLean });
    const repository = new MongoOrderRepository(
      { findOneAndUpdate: orderFindOneAndUpdate } as unknown as Model<OrderMongoose>,
      {} as Model<CounterMongoose>,
      {} as Model<StatusHistoryMongoose>,
      { findOneAndUpdate: assignmentFindOneAndUpdate } as unknown as Model<AssignmentMongoose>,
      { transaction } as unknown as Connection,
    );

    const result = await repository.assign(scope, ORDER_ID, WORKER_ID);

    const orderCalls = orderFindOneAndUpdate.mock.calls as unknown as readonly (readonly [
      Record<string, unknown>,
      unknown,
      Record<string, unknown>,
    ])[];
    expect(orderCalls[0]?.[0]).toEqual({
      _id: ORDER_ID,
      assignedTo: { $ne: new Types.ObjectId(WORKER_ID) },
      branchId: scope.branchId,
      status: { $nin: [OrderStatus.DELIVERED, OrderStatus.CANCELLED] },
      tenantId: scope.tenantId,
    });
    expect(orderCalls[0]?.[2]).toEqual(expect.objectContaining({ session }));
    expect(result?.assignment).toMatchObject({
      assignedBy: ACTOR_ID,
      assignedTo: WORKER_ID,
      orderId: ORDER_ID,
      status: 'Assigned',
    });
  });

  it('marks Delivered and writes its history in the same scoped transaction', async () => {
    const session = {} as ClientSession;
    const transaction = jest.fn(
      async (operation: (activeSession: ClientSession) => Promise<unknown>): Promise<unknown> =>
        operation(session),
    );
    const orderFindOneAndUpdate = jest.fn(
      (
        _filter: Record<string, unknown>,
        update: { $set: { deliveryDate?: Date; status: OrderStatus } },
      ): { lean: () => { exec: () => Promise<Record<string, unknown>> } } => {
        const exec = jest
          .fn()
          .mockResolvedValue(
            persistedOrder(update.$set.status, { deliveryDate: update.$set.deliveryDate }),
          );
        return { lean: () => ({ exec }) };
      },
    );
    const historyCreate = jest.fn().mockResolvedValue([]);
    const repository = new MongoOrderRepository(
      { findOneAndUpdate: orderFindOneAndUpdate } as unknown as Model<OrderMongoose>,
      {} as Model<CounterMongoose>,
      { create: historyCreate } as unknown as Model<StatusHistoryMongoose>,
      {} as Model<AssignmentMongoose>,
      { transaction } as unknown as Connection,
    );

    const result = await repository.transition(
      scope,
      ORDER_ID,
      OrderStatus.READY,
      OrderStatus.DELIVERED,
      'Collected',
    );

    const orderCalls = orderFindOneAndUpdate.mock.calls as unknown as readonly (readonly [
      Record<string, unknown>,
      { $set: { deliveryDate: Date; status: OrderStatus } },
      Record<string, unknown>,
    ])[];
    expect(orderCalls[0]?.[0]).toEqual({
      _id: ORDER_ID,
      branchId: scope.branchId,
      status: OrderStatus.READY,
      tenantId: scope.tenantId,
    });
    expect(orderCalls[0]?.[1].$set.deliveryDate).toBeInstanceOf(Date);
    expect(orderCalls[0]?.[2]).toEqual(expect.objectContaining({ session }));
    expect(result).toMatchObject({ status: OrderStatus.DELIVERED });
    expect(result?.deliveryDate).toEqual(orderCalls[0]?.[1].$set.deliveryDate);

    const historyCalls = historyCreate.mock.calls as unknown as readonly (readonly [
      readonly Record<string, unknown>[],
      { session: ClientSession },
    ])[];
    const deliveredHistory = historyCalls[0]?.[0][0];
    expect(deliveredHistory).toEqual(
      expect.objectContaining({
        branchId: scope.branchId,
        changedBy: new Types.ObjectId(ACTOR_ID),
        newStatus: OrderStatus.DELIVERED,
        note: 'Collected',
        orderId: new Types.ObjectId(ORDER_ID),
        previousStatus: OrderStatus.READY,
        tenantId: new Types.ObjectId(TENANT_ID),
      }),
    );
    expect(deliveredHistory?.timestamp).toBeInstanceOf(Date);
    expect(historyCalls[0]?.[1]).toEqual({ session });
  });

  it('returns chronological status history from a tenant-and-branch scoped query', async () => {
    const timestamp = new Date('2026-08-14T10:00:00.000Z');
    const historyExec = jest.fn().mockResolvedValue([
      {
        _id: new Types.ObjectId(),
        changedBy: new Types.ObjectId(ACTOR_ID),
        newStatus: OrderStatus.IN_PROGRESS,
        note: 'Started',
        orderId: new Types.ObjectId(ORDER_ID),
        previousStatus: OrderStatus.RECEIVED,
        timestamp,
      },
    ]);
    const historyLean = jest.fn().mockReturnValue({ exec: historyExec });
    const historySort = jest.fn().mockReturnValue({ lean: historyLean });
    const historyFind = jest.fn().mockReturnValue({ sort: historySort });
    const repository = new MongoOrderRepository(
      {} as Model<OrderMongoose>,
      {} as Model<CounterMongoose>,
      { find: historyFind } as unknown as Model<StatusHistoryMongoose>,
      {} as Model<AssignmentMongoose>,
      {} as Connection,
    );

    const result = await repository.history(scope, ORDER_ID);
    const historyFindCalls = historyFind.mock.calls as unknown as readonly (readonly [
      Record<string, unknown>,
    ])[];
    expect(historyFindCalls[0]?.[0]).toEqual({
      branchId: scope.branchId,
      orderId: ORDER_ID,
      tenantId: scope.tenantId,
    });
    expect(historySort.mock.calls).toContainEqual([{ _id: 1, timestamp: 1 }]);
    expect(result).toEqual([
      expect.objectContaining({
        changedBy: ACTOR_ID,
        newStatus: OrderStatus.IN_PROGRESS,
        note: 'Started',
        previousStatus: OrderStatus.RECEIVED,
        timestamp,
      }),
    ]);
  });
});
