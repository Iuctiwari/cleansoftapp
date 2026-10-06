/* eslint-disable @typescript-eslint/unbound-method */
import 'reflect-metadata';

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  ValidationPipe,
} from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';

import { BulkAssignDto } from '../src/order/dtos/bulk-assign.dto';
import { OrderPaymentStatus, OrderStatus } from '../src/order/enums';
import type { OrderAuditService } from '../src/order/order-audit.service';
import type { OrderOwnerLookupService } from '../src/order/order-owner.service';
import { OrderService } from '../src/order/order.service';
import {
  DeclineConflictError,
  type DeclineRequestRecord,
  type OrderDependencies,
  type OrderRecord,
  type OrderRepository,
  type OrderScope,
} from '../src/order/order.types';

const OWNER_ID = '64f0c18f7c4d2f0012ab34aa';
const TENANT_ID = '64f0c18f7c4d2f0012ab34bb';
const ORDER_ID = '64f0c18f7c4d2f0012ab34ff';
const ITEM_ID = '64f0c18f7c4d2f0012ab3402';
const RAVI = '64f0c18f7c4d2f0012ab3501';
const SUNITA = '64f0c18f7c4d2f0012ab3502';
const AMIT = '64f0c18f7c4d2f0012ab3503';

function ownerScope(overrides: Partial<OrderScope> = {}): OrderScope {
  return {
    actorId: OWNER_ID,
    authorization: 'Bearer token',
    branchId: 'branch-a',
    permissions: ['orders:read', 'orders:write'],
    roleCode: 'tenant_owner',
    tenantId: TENANT_ID,
    ...overrides,
  };
}

function workerScope(workerId = RAVI): OrderScope {
  return ownerScope({ actorId: workerId, roleCode: 'Staff' });
}

let orderCounter = 0;
function order(overrides: Partial<OrderRecord> = {}): OrderRecord {
  orderCounter += 1;
  const now = new Date('2026-10-05T10:00:00.000Z');
  return {
    branchId: 'branch-a',
    createdAt: now,
    createdBy: OWNER_ID,
    customerId: '64f0c18f7c4d2f0012ab34cc',
    customerSnapshot: { name: 'Customer' },
    discount: 0,
    discountPercentage: 0,
    grandTotal: 100,
    id: ORDER_ID,
    items: [
      {
        discount: 0,
        id: ITEM_ID,
        itemCategoryId: '64f0c18f7c4d2f0012ab34ee',
        itemCategorySnapshot: { name: 'Blue shirt' },
        lineTotal: 100,
        quantity: 1,
        serviceId: '64f0c18f7c4d2f0012ab34dd',
        serviceSnapshot: { name: 'Wash' },
        tax: 0,
        unitPrice: 100,
      },
    ],
    orderNumber: `ORD-BRA-${String(orderCounter).padStart(6, '0')}`,
    outstandingAmount: 100,
    paidAmount: 0,
    paymentStatus: OrderPaymentStatus.UNPAID,
    status: OrderStatus.RECEIVED,
    subtotal: 100,
    tax: 0,
    tenantId: TENANT_ID,
    updatedAt: now,
    version: 0,
    ...overrides,
  };
}

function withDecline(
  base: OrderRecord,
  status: DeclineRequestRecord['status'] = 'Pending',
): OrderRecord {
  return {
    ...base,
    assignment: {
      assignedBy: OWNER_ID,
      assignedTo: base.assignedTo ?? RAVI,
      createdAt: base.createdAt,
      declineRequest: {
        reason: 'I am on leave tomorrow',
        requestedAt: base.createdAt,
        requestedBy: base.assignedTo ?? RAVI,
        status,
      },
      id: 'assignment-1',
      orderId: base.id,
      status: 'Assigned',
      updatedAt: base.createdAt,
      version: 0,
    },
  };
}

describe('Worker tasks: decline requests, notes, workload, bulk assignment', () => {
  let repository: jest.Mocked<OrderRepository>;
  let dependencies: jest.Mocked<OrderDependencies>;
  let ownerLookup: jest.Mocked<Pick<OrderOwnerLookupService, 'findOwnerId'>>;
  let service: OrderService;
  let sent: Array<{ recipientId: string; type: string; message: string }>;
  const originalFetch = global.fetch;

  /** Notifications are fire-and-forget; let their promises settle. */
  const flush = (): Promise<void> => new Promise((resolve) => setImmediate(resolve));

  beforeEach(() => {
    sent = [];
    global.fetch = jest.fn((_url: unknown, init?: RequestInit) => {
      sent.push(JSON.parse(init?.body as string) as (typeof sent)[number]);
      return Promise.resolve(new Response('{}', { status: 201 }));
    }) as typeof fetch;

    repository = {
      acceptAssignment: jest.fn(),
      addNote: jest.fn(),
      applyPaymentProjection: jest.fn(),
      assign: jest.fn(),
      create: jest.fn(),
      findById: jest.fn(),
      getSummaryForTenant: jest.fn(),
      history: jest.fn(),
      list: jest.fn().mockResolvedValue({ items: [], limit: 20, page: 1, total: 0, totalPages: 0 }),
      listPendingDeclines: jest.fn(),
      openCounts: jest.fn().mockResolvedValue({}),
      rejectAssignment: jest.fn(),
      requestDecline: jest.fn(),
      resolveDecline: jest.fn(),
      statistics: jest.fn(),
      transition: jest.fn(),
      update: jest.fn(),
      workload: jest.fn(),
    };
    dependencies = {
      assertStaffEligible: jest.fn().mockResolvedValue(undefined),
      quoteCatalog: jest.fn(),
      resolveBranch: jest.fn(),
      resolveCustomer: jest.fn(),
      validateCatalogReference: jest.fn(),
    };
    ownerLookup = { findOwnerId: jest.fn().mockResolvedValue(OWNER_ID) };
    service = new OrderService(
      repository,
      dependencies,
      { record: jest.fn() } as unknown as OrderAuditService,
      { get: jest.fn().mockReturnValue('http://notify.test') } as unknown as ConfigService,
      ownerLookup as unknown as OrderOwnerLookupService,
    );
  });

  afterEach(() => {
    global.fetch = originalFetch;
  });

  describe('decline requests', () => {
    it('lets the assigned worker ask to be taken off and tells the owner', async () => {
      const assigned = order({ assignedTo: RAVI, status: OrderStatus.ACCEPTED });
      repository.findById.mockResolvedValue(assigned);
      repository.requestDecline.mockResolvedValue(withDecline(assigned));

      const result = await service.requestDecline(workerScope(), ORDER_ID, '  On leave  ');
      await flush();

      expect(repository.requestDecline).toHaveBeenCalledWith(
        workerScope(),
        ORDER_ID,
        RAVI,
        'On leave',
      );
      // The order is still the worker's until the owner decides.
      expect(result.assignedTo).toBe(RAVI);
      expect(result.assignment?.declineRequest?.status).toBe('Pending');
      expect(sent).toEqual([
        expect.objectContaining({ recipientId: OWNER_ID, type: 'WorkerDeclineRequested' }),
      ]);
    });

    it('refuses requests from owners, other workers, finished orders and duplicates', async () => {
      repository.findById.mockResolvedValue(
        order({ assignedTo: RAVI, status: OrderStatus.ASSIGNED }),
      );
      await expect(service.requestDecline(ownerScope(), ORDER_ID, 'x')).rejects.toBeInstanceOf(
        ForbiddenException,
      );
      await expect(
        service.requestDecline(workerScope(SUNITA), ORDER_ID, 'x'),
      ).rejects.toBeInstanceOf(ForbiddenException);
      await expect(service.requestDecline(workerScope(), ORDER_ID, '   ')).rejects.toBeInstanceOf(
        BadRequestException,
      );

      repository.findById.mockResolvedValue(order({ assignedTo: RAVI, status: OrderStatus.READY }));
      await expect(service.requestDecline(workerScope(), ORDER_ID, 'x')).rejects.toBeInstanceOf(
        ConflictException,
      );

      repository.findById.mockResolvedValue(
        withDecline(order({ assignedTo: RAVI, status: OrderStatus.ASSIGNED })),
      );
      await expect(service.requestDecline(workerScope(), ORDER_ID, 'x')).rejects.toThrow(
        'already waiting',
      );
      expect(repository.requestDecline).not.toHaveBeenCalled();
    });

    it('owner approves: order is unassigned and the worker is told', async () => {
      const pending = withDecline(order({ assignedTo: RAVI, status: OrderStatus.ACCEPTED }));
      repository.findById.mockResolvedValue(pending);
      repository.resolveDecline.mockResolvedValue({
        ...withDecline(order({ status: OrderStatus.RECEIVED }), 'Approved'),
        assignedTo: undefined,
      });

      const result = await service.resolveDecline(ownerScope(), ORDER_ID, true, ' Ok, get well ');
      await flush();

      expect(repository.resolveDecline).toHaveBeenCalledWith(
        ownerScope(),
        ORDER_ID,
        true,
        'Ok, get well',
      );
      expect(result.assignedTo).toBeUndefined();
      expect(result.status).toBe(OrderStatus.RECEIVED);
      expect(sent).toEqual([
        expect.objectContaining({ recipientId: RAVI, type: 'WorkerDeclineApproved' }),
      ]);
      expect(sent[0].message).toContain('Ok, get well');
    });

    it('owner denies: worker keeps the order and is told to complete it', async () => {
      const pending = withDecline(order({ assignedTo: RAVI, status: OrderStatus.ASSIGNED }));
      repository.findById.mockResolvedValue(pending);
      repository.resolveDecline.mockResolvedValue(withDecline(pending, 'Denied'));

      const result = await service.resolveDecline(ownerScope(), ORDER_ID, false);
      await flush();

      expect(result.assignedTo).toBe(RAVI);
      expect(sent).toEqual([
        expect.objectContaining({ recipientId: RAVI, type: 'WorkerDeclineDenied' }),
      ]);
    });

    it('only managers resolve, and only pending requests', async () => {
      repository.findById.mockResolvedValue(
        withDecline(order({ assignedTo: RAVI, status: OrderStatus.ASSIGNED })),
      );
      await expect(service.resolveDecline(workerScope(), ORDER_ID, true)).rejects.toBeInstanceOf(
        ForbiddenException,
      );

      repository.findById.mockResolvedValue(
        order({ assignedTo: RAVI, status: OrderStatus.ASSIGNED }),
      );
      await expect(service.resolveDecline(ownerScope(), ORDER_ID, true)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });

    it('turns a concurrent change during approval into a 409', async () => {
      repository.findById.mockResolvedValue(
        withDecline(order({ assignedTo: RAVI, status: OrderStatus.ASSIGNED })),
      );
      repository.resolveDecline.mockRejectedValue(new DeclineConflictError());
      await expect(service.resolveDecline(ownerScope(), ORDER_ID, true)).rejects.toBeInstanceOf(
        ConflictException,
      );
    });
  });

  describe('order notes', () => {
    it('a worker reports damage on a specific item and the owner is alerted', async () => {
      const assigned = order({ assignedTo: RAVI, status: OrderStatus.IN_PROGRESS });
      repository.findById.mockResolvedValue(assigned);
      repository.addNote.mockResolvedValue(assigned);

      await service.addNote(workerScope(), ORDER_ID, {
        itemId: ITEM_ID,
        kind: 'Damage',
        text: ' Sleeve torn before washing ',
      });
      await flush();

      expect(repository.addNote).toHaveBeenCalledWith(
        workerScope(),
        ORDER_ID,
        expect.objectContaining({
          authorId: RAVI,
          authorRole: 'Staff',
          itemId: ITEM_ID,
          kind: 'Damage',
          text: 'Sleeve torn before washing',
        }),
      );
      expect(sent).toEqual([
        expect.objectContaining({ recipientId: OWNER_ID, type: 'OrderDamageReported' }),
      ]);
      expect(sent[0].message).toContain('Blue shirt');
    });

    it("an owner's note goes to the assigned worker; unknown items are refused", async () => {
      const assigned = order({ assignedTo: RAVI, status: OrderStatus.ACCEPTED });
      repository.findById.mockResolvedValue(assigned);
      repository.addNote.mockResolvedValue(assigned);

      await service.addNote(ownerScope(), ORDER_ID, { text: 'Use cold wash' });
      await flush();
      expect(sent).toEqual([
        expect.objectContaining({ recipientId: RAVI, type: 'OrderNoteAdded' }),
      ]);

      await expect(
        service.addNote(ownerScope(), ORDER_ID, {
          itemId: '64f0c18f7c4d2f0012ab9999',
          text: 'x',
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('workers can only note their own orders (others are not found for them)', async () => {
      repository.findById.mockResolvedValue(null);
      await expect(service.addNote(workerScope(SUNITA), ORDER_ID, { text: 'x' })).rejects.toThrow(
        'Order not found',
      );
      expect(repository.findById).toHaveBeenCalledWith(workerScope(SUNITA), ORDER_ID, SUNITA);
    });
  });

  describe('bulk assignment', () => {
    function pool(count: number): OrderRecord[] {
      return Array.from({ length: count }, (_, index) =>
        order({
          expectedDeliveryDate: new Date(Date.UTC(2026, 9, 10 + (index % 5))),
          id: `64f0c18f7c4d2f0012ab${String(4000 + index).padStart(4, '0')}`,
        }),
      );
    }

    function serve(orders: OrderRecord[]): void {
      const byId = new Map(orders.map((item) => [item.id, item]));
      repository.findById.mockImplementation((_scope, id) => Promise.resolve(byId.get(id) ?? null));
      repository.assign.mockImplementation((_scope, id, workerId) =>
        Promise.resolve({ ...byId.get(id)!, assignedTo: workerId, status: OrderStatus.ASSIGNED }),
      );
    }

    it('auto splits 100 orders evenly over 10 workers (10 each)', async () => {
      const orders = pool(100);
      serve(orders);
      const workers = Array.from(
        { length: 10 },
        (_, index) => `64f0c18f7c4d2f0012ab${String(3600 + index).padStart(4, '0')}`,
      );

      const result = await service.bulkAssign(ownerScope(), {
        mode: 'auto',
        orderIds: orders.map((item) => item.id),
        workerIds: workers,
      });
      await flush();

      const perWorker = new Map<string, number>();
      for (const entry of result.assigned) {
        perWorker.set(entry.workerId, (perWorker.get(entry.workerId) ?? 0) + 1);
      }
      expect(result.assigned).toHaveLength(100);
      expect([...perWorker.values()]).toEqual(Array(10).fill(10));
      // One summary per worker + one for the owner, not 100+ notifications.
      expect(sent.filter((item) => item.recipientId !== OWNER_ID)).toHaveLength(10);
      expect(sent.filter((item) => item.recipientId === OWNER_ID)).toHaveLength(1);
    });

    it('auto gives fewer new orders to workers who are already busy', async () => {
      const orders = pool(9);
      serve(orders);
      repository.openCounts.mockResolvedValue({ [RAVI]: 6, [SUNITA]: 0, [AMIT]: 0 });

      const result = await service.bulkAssign(ownerScope(), {
        dryRun: true,
        mode: 'auto',
        orderIds: orders.map((item) => item.id),
        workerIds: [RAVI, SUNITA, AMIT],
      });

      const count = (workerId: string): number =>
        result.plan.filter((entry) => entry.workerId === workerId).length;
      // Ravi already has 6 open orders; 9 new ones only bring Sunita and Amit to 5 and 4,
      // so all 9 go to them and none to Ravi.
      expect(count(RAVI)).toBe(0);
      expect(count(SUNITA) + count(AMIT)).toBe(9);
      expect(Math.abs(count(SUNITA) - count(AMIT))).toBeLessThanOrEqual(1);
      // Dry run writes nothing and notifies nobody.
      expect(result.dryRun).toBe(true);
      expect(repository.assign).not.toHaveBeenCalled();
      await flush();
      expect(sent).toHaveLength(0);
    });

    it('auto takes the earliest expected delivery first and skips assigned/finished orders', async () => {
      const late = order({
        expectedDeliveryDate: new Date('2026-10-20T00:00:00Z'),
        id: '64f0c18f7c4d2f0012ab4101',
      });
      const early = order({
        expectedDeliveryDate: new Date('2026-10-06T00:00:00Z'),
        id: '64f0c18f7c4d2f0012ab4102',
      });
      const taken = order({ assignedTo: AMIT, id: '64f0c18f7c4d2f0012ab4103' });
      const done = order({ id: '64f0c18f7c4d2f0012ab4104', status: OrderStatus.DELIVERED });
      serve([late, early, taken, done]);

      const result = await service.bulkAssign(ownerScope(), {
        dryRun: true,
        mode: 'auto',
        orderIds: [late.id, early.id, taken.id, done.id, '64f0c18f7c4d2f0012ab4199'],
        workerIds: [RAVI, SUNITA],
      });

      expect(result.plan.map((entry) => entry.orderId)).toEqual([early.id, late.id]);
      expect(result.skipped.map((entry) => entry.reason)).toEqual([
        'Already assigned',
        'Order is finished',
        'Order not found',
      ]);
    });

    it('manual gives everything to one worker (reassigning is allowed)', async () => {
      const orders = [
        order({ id: '64f0c18f7c4d2f0012ab4201' }),
        order({
          assignedTo: AMIT,
          id: '64f0c18f7c4d2f0012ab4202',
        }),
      ];
      serve(orders);

      const result = await service.bulkAssign(ownerScope(), {
        mode: 'manual',
        orderIds: orders.map((item) => item.id),
        workerIds: [RAVI],
      });

      expect(result.assigned.map((entry) => entry.workerId)).toEqual([RAVI, RAVI]);
      await expect(
        service.bulkAssign(ownerScope(), {
          mode: 'manual',
          orderIds: [orders[0].id],
          workerIds: [RAVI, SUNITA],
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('reports orders that changed mid-way, rejects ineligible workers and non-managers', async () => {
      const orders = pool(2);
      serve(orders);
      repository.assign.mockResolvedValueOnce(null);

      const result = await service.bulkAssign(ownerScope(), {
        mode: 'manual',
        orderIds: orders.map((item) => item.id),
        workerIds: [RAVI],
      });
      expect(result.failed).toHaveLength(1);
      expect(result.assigned).toHaveLength(1);

      dependencies.assertStaffEligible.mockRejectedValueOnce(new BadRequestException('Inactive'));
      await expect(
        service.bulkAssign(ownerScope(), {
          mode: 'manual',
          orderIds: [orders[0].id],
          workerIds: [SUNITA],
        }),
      ).rejects.toThrow('Inactive');

      await expect(
        service.bulkAssign(workerScope(), {
          mode: 'manual',
          orderIds: [orders[0].id],
          workerIds: [RAVI],
        }),
      ).rejects.toBeInstanceOf(ForbiddenException);
    });

    it('validates the request body (limits, ids, duplicates)', async () => {
      const pipe = new ValidationPipe({ transform: true, whitelist: true });
      const transform = (body: unknown): Promise<unknown> =>
        pipe.transform(body, { metatype: BulkAssignDto, type: 'body' });

      await expect(
        transform({ mode: 'auto', orderIds: [ORDER_ID, ORDER_ID], workerIds: [RAVI] }),
      ).rejects.toBeInstanceOf(BadRequestException);
      await expect(
        transform({ mode: 'everyone', orderIds: [ORDER_ID], workerIds: [RAVI] }),
      ).rejects.toBeInstanceOf(BadRequestException);
      await expect(
        transform({
          mode: 'auto',
          orderIds: Array.from(
            { length: 201 },
            (_, index) => `64f0c18f7c4d2f0012ab${String(5000 + index).padStart(4, '0')}`,
          ),
          workerIds: [RAVI],
        }),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('lists, workload and status notifications', () => {
    it('owners can filter by worker / unassigned / overdue; workers always see only theirs', async () => {
      await service.list(ownerScope(), {
        assignedTo: SUNITA,
        limit: 20,
        overdue: true,
        page: 1,
      } as never);
      expect(repository.list).toHaveBeenLastCalledWith(
        ownerScope(),
        expect.objectContaining({
          assignedTo: SUNITA,
          overdueBefore: expect.any(Date) as Date,
        }),
      );

      await service.list(workerScope(), {
        assignedTo: SUNITA,
        limit: 20,
        page: 1,
        unassigned: true,
      } as never);
      const workerQuery = repository.list.mock.calls.at(-1)?.[1];
      expect(workerQuery?.assignedTo).toBe(RAVI);
      expect(workerQuery?.unassigned).toBeUndefined();
    });

    it('workload is for managers only', async () => {
      repository.workload.mockResolvedValue({
        generatedAt: new Date(),
        pendingDeclineRequests: 0,
        unassigned: 3,
        workers: [],
      });
      await expect(service.workload(ownerScope())).resolves.toMatchObject({ unassigned: 3 });
      expect(() => service.workload(workerScope())).toThrow(ForbiddenException);
    });

    it('marking an order Ready notifies the owner', async () => {
      const inProgress = order({ assignedTo: RAVI, status: OrderStatus.IN_PROGRESS });
      repository.findById.mockResolvedValue(inProgress);
      repository.transition.mockResolvedValue({ ...inProgress, status: OrderStatus.READY });

      await service.changeStatus(workerScope(), ORDER_ID, { status: OrderStatus.READY });
      await flush();

      expect(sent).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ recipientId: OWNER_ID, type: 'OrderReady' }),
        ]),
      );
    });
  });
});
