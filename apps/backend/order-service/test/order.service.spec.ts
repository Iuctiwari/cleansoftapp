/* eslint-disable @typescript-eslint/unbound-method */
import 'reflect-metadata';

import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';
import { SortDirection } from '@nexoraa/constants';

import { CreateOrderDto } from '../src/order/dtos/create-order.dto';
import { OrderQueryDto } from '../src/order/dtos/order-query.dto';
import { OrderPaymentStatus, OrderStatus } from '../src/order/enums';
import type { OrderAuditService } from '../src/order/order-audit.service';
import type { OrderOwnerLookupService } from '../src/order/order-owner.service';
import { OrderService } from '../src/order/order.service';
import type {
  OrderDependencies,
  OrderRecord,
  OrderRepository,
  OrderScope,
} from '../src/order/order.types';

const ACTOR_ID = '64f0c18f7c4d2f0012ab34aa';
const TENANT_ID = '64f0c18f7c4d2f0012ab34bb';
const CUSTOMER_ID = '64f0c18f7c4d2f0012ab34cc';
const SERVICE_ID = '64f0c18f7c4d2f0012ab34dd';
const SECOND_SERVICE_ID = '64f0c18f7c4d2f0012ab3403';
const CATEGORY_ID = '64f0c18f7c4d2f0012ab34ee';
const ORDER_ID = '64f0c18f7c4d2f0012ab34ff';
const STAFF_ID = '64f0c18f7c4d2f0012ab3401';

function scope(overrides: Partial<OrderScope> = {}): OrderScope {
  return {
    actorId: ACTOR_ID,
    authorization: 'Bearer token',
    branchId: 'branch-a',
    permissions: ['orders:read', 'orders:write'],
    roleCode: 'tenant_owner',
    tenantId: TENANT_ID,
    ...overrides,
  };
}

function order(overrides: Partial<OrderRecord> = {}): OrderRecord {
  const now = new Date('2026-08-13T10:00:00.000Z');
  return {
    branchId: 'branch-a',
    createdAt: now,
    createdBy: ACTOR_ID,
    customerId: CUSTOMER_ID,
    customerSnapshot: { id: CUSTOMER_ID, name: 'Customer' },
    discount: 5,
    discountPercentage: 0,
    grandTotal: 105,
    id: ORDER_ID,
    items: [
      {
        discount: 0,
        id: '64f0c18f7c4d2f0012ab3402',
        itemCategoryId: CATEGORY_ID,
        itemCategorySnapshot: { id: CATEGORY_ID, name: 'Shirt' },
        lineTotal: 100,
        quantity: 2,
        serviceId: SERVICE_ID,
        serviceSnapshot: { id: SERVICE_ID, name: 'Wash' },
        tax: 0,
        unitPrice: 50,
      },
    ],
    orderNumber: 'ORD-BRA-000001',
    outstandingAmount: 105,
    paidAmount: 0,
    paymentStatus: OrderPaymentStatus.UNPAID,
    status: OrderStatus.RECEIVED,
    subtotal: 100,
    tax: 10,
    tenantId: TENANT_ID,
    updatedAt: now,
    version: 0,
    ...overrides,
  };
}

describe('OrderService API use cases', () => {
  let repository: jest.Mocked<OrderRepository>;
  let dependencies: jest.Mocked<OrderDependencies>;
  let audit: jest.Mocked<Pick<OrderAuditService, 'record'>>;
  let ownerLookup: jest.Mocked<Pick<OrderOwnerLookupService, 'findOwnerId'>>;
  let service: OrderService;

  beforeEach(() => {
    repository = {
      acceptAssignment: jest.fn(),
      applyPaymentProjection: jest.fn(),
      assign: jest.fn(),
      create: jest.fn(),
      findById: jest.fn(),
      getSummaryForTenant: jest.fn(),
      history: jest.fn(),
      list: jest.fn(),
      rejectAssignment: jest.fn(),
      statistics: jest.fn(),
      transition: jest.fn(),
      update: jest.fn(),
    };
    dependencies = {
      assertStaffEligible: jest.fn().mockResolvedValue(undefined),
      quoteCatalog: jest.fn().mockResolvedValue({
        itemCategorySnapshot: { id: CATEGORY_ID, name: 'Shirt' },
        pricingType: 'PerItem',
        serviceSnapshot: { id: SERVICE_ID, name: 'Wash' },
        taxPercent: 10,
        unitPrice: 50,
      }),
      resolveBranch: jest.fn().mockResolvedValue({ branchId: 'branch-a', code: 'BRA' }),
      resolveCustomer: jest.fn().mockResolvedValue({
        customerId: CUSTOMER_ID,
        customerType: 'Regular',
        name: 'Customer',
      }),
      validateCatalogReference: jest.fn().mockResolvedValue(undefined),
    };
    audit = { record: jest.fn() };
    // Defaults to "no owner found" so existing recipient-targeted assertions
    // are unaffected; owner-notification behavior is covered separately.
    ownerLookup = { findOwnerId: jest.fn().mockResolvedValue(undefined) };
    const configService = { get: jest.fn().mockReturnValue('http://localhost:3015') };
    service = new OrderService(
      repository,
      dependencies,
      audit as unknown as OrderAuditService,
      configService as unknown as ConfigService,
      ownerLookup as unknown as OrderOwnerLookupService,
    );
  });

  it('creates a Received order using validated snapshots and authoritative totals', async () => {
    repository.create.mockImplementation((_scope, input) =>
      Promise.resolve(
        order({
          assignedTo: input.assignedTo,
          discount: input.discount,
          grandTotal: input.grandTotal,
          items: input.items.map((item, index) => ({ ...item, id: `${index}` })),
          outstandingAmount: input.outstandingAmount,
          subtotal: input.subtotal,
          tax: input.tax,
        }),
      ),
    );

    const result = await service.create(scope(), {
      assignedTo: STAFF_ID,
      customerId: CUSTOMER_ID,
      discount: 5,
      items: [
        {
          discount: 0,
          itemCategoryId: CATEGORY_ID,
          quantity: 2,
          serviceId: SERVICE_ID,
          tax: 0,
        },
      ],
      tax: 10,
    });

    expect(dependencies.resolveCustomer.mock.calls).toContainEqual([
      expect.anything(),
      CUSTOMER_ID,
    ]);
    expect(dependencies.quoteCatalog.mock.calls).toContainEqual([
      expect.anything(),
      SERVICE_ID,
      CATEGORY_ID,
    ]);
    expect(dependencies.assertStaffEligible.mock.calls).toContainEqual([
      expect.anything(),
      STAFF_ID,
    ]);
    expect(repository.create.mock.calls[0]?.[1]).toEqual(
      expect.objectContaining({
        customerSnapshot: {
          customerId: CUSTOMER_ID,
          customerType: 'Regular',
          name: 'Customer',
        },
        grandTotal: 104.5,
        outstandingAmount: 104.5,
        subtotal: 100,
      }),
    );
    expect(result.status).toBe(OrderStatus.RECEIVED);
    expect(result.customerSnapshot.name).toBe('Customer');
    expect(result.items[0]?.itemCategorySnapshot).toBeDefined();
    expect(result.items[0]?.lineTotal).toBe(110);
    expect(result.items[0]?.serviceSnapshot).toBeDefined();
    expect(result.items[0]?.unitPrice).toBe(50);
    expect(result.orderNumber).toBe('ORD-BRA-000001');
    expect(result.outstandingAmount).toBe(104.5);
    expect(result.paidAmount).toBe(0);
    expect(result.paymentStatus).toBe(OrderPaymentStatus.UNPAID);
    expect(audit.record).toHaveBeenCalledWith(
      expect.anything(),
      'order.created',
      ORDER_ID,
      expect.anything(),
    );
  });

  it('uses quote tax and ignores client-calculated line and order tax values', async () => {
    repository.create.mockImplementation((_scope, input) =>
      Promise.resolve(
        order({
          discount: input.discount,
          grandTotal: input.grandTotal,
          items: input.items.map((item, index) => ({ ...item, id: `${index}` })),
          outstandingAmount: input.outstandingAmount,
          subtotal: input.subtotal,
          tax: input.tax,
        }),
      ),
    );

    await service.create(scope(), {
      customerId: CUSTOMER_ID,
      discount: 5,
      items: [
        {
          discount: 0,
          itemCategoryId: CATEGORY_ID,
          quantity: 2,
          serviceId: SERVICE_ID,
          tax: 999,
        },
      ],
      tax: 999,
    });

    expect(repository.create.mock.calls[0]?.[1]).toEqual(
      expect.objectContaining({
        grandTotal: 104.5,
        subtotal: 100,
        tax: 9.5,
        items: [expect.objectContaining({ lineTotal: 110, tax: 10, unitPrice: 50 })],
      }),
    );
  });

  it('calculates a percentage discount and tax server-side', async () => {
    repository.create.mockImplementation((_scope, input) =>
      Promise.resolve(
        order({
          discount: input.discount,
          discountPercentage: input.discountPercentage,
          grandTotal: input.grandTotal,
          items: input.items.map((item, index) => ({ ...item, id: `${index}` })),
          outstandingAmount: input.outstandingAmount,
          subtotal: input.subtotal,
          tax: input.tax,
        }),
      ),
    );

    await service.create(scope(), {
      customerId: CUSTOMER_ID,
      discount: 0,
      discountPercentage: 10,
      items: [
        {
          discount: 0,
          itemCategoryId: CATEGORY_ID,
          quantity: 2,
          serviceId: SERVICE_ID,
          tax: 0,
        },
      ],
      tax: 0,
    });

    expect(repository.create.mock.calls[0]?.[1]).toEqual(
      expect.objectContaining({
        discount: 10,
        discountPercentage: 10,
        grandTotal: 99,
        outstandingAmount: 99,
        subtotal: 100,
        tax: 9,
      }),
    );
  });

  it('keeps one catalog price and applies only the incremental surcharge for more services', async () => {
    repository.create.mockImplementation((_scope, input) =>
      Promise.resolve(
        order({
          discount: input.discount,
          discountPercentage: input.discountPercentage,
          grandTotal: input.grandTotal,
          items: input.items.map((item, index) => ({ ...item, id: `${index}` })),
          outstandingAmount: input.outstandingAmount,
          subtotal: input.subtotal,
          tax: input.tax,
        }),
      ),
    );

    const result = await service.create(scope(), {
      customerId: CUSTOMER_ID,
      discount: 0,
      items: [SERVICE_ID, SECOND_SERVICE_ID].map((serviceId) => ({
        discount: 0,
        itemCategoryId: CATEGORY_ID,
        quantity: 2,
        serviceId,
        tax: 0,
      })),
      tax: 0,
    });

    expect(result.items).toHaveLength(2);
    expect(result.items.map((item) => item.serviceId)).toEqual([SERVICE_ID, SECOND_SERVICE_ID]);
    expect(result.items.map((item) => item.unitPrice)).toEqual([50, 10]);
    expect(result.subtotal).toBe(120);
    expect(dependencies.quoteCatalog.mock.calls).toHaveLength(2);
  });

  it.each([
    [1, 100],
    [2, 110],
    [3, 120],
    [4, 130],
  ])(
    'prices %i selected service(s) as one base price plus incremental surcharges',
    async (serviceCount, expectedSubtotal) => {
      dependencies.quoteCatalog.mockResolvedValue({
        itemCategorySnapshot: { id: CATEGORY_ID, name: 'Shirt' },
        pricingType: 'PerItem',
        serviceSnapshot: { name: 'Selected service' },
        taxPercent: 0,
        unitPrice: 100,
      });
      repository.create.mockImplementation((_scope, input) =>
        Promise.resolve(
          order({
            discount: input.discount,
            discountPercentage: input.discountPercentage,
            grandTotal: input.grandTotal,
            items: input.items.map((item, index) => ({ ...item, id: `${index}` })),
            outstandingAmount: input.outstandingAmount,
            subtotal: input.subtotal,
            tax: input.tax,
          }),
        ),
      );

      const result = await service.create(scope(), {
        customerId: CUSTOMER_ID,
        discount: 0,
        items: Array.from({ length: serviceCount }, (_, index) => ({
          discount: 0,
          itemCategoryId: CATEGORY_ID,
          quantity: 1,
          serviceId: `64f0c18f7c4d2f0012ab${(3500 + index).toString(16)}`,
          tax: 0,
        })),
        tax: 0,
      });

      expect(result.subtotal).toBe(expectedSubtotal);
      expect(result.items.map((item) => item.unitPrice)).toEqual([
        100,
        ...Array.from({ length: Math.max(serviceCount - 1, 0) }, () => 10),
      ]);
    },
  );

  it('calculates weight-priced items and validates the quote pricing type', async () => {
    dependencies.quoteCatalog.mockResolvedValueOnce({
      itemCategorySnapshot: { id: CATEGORY_ID, name: 'Carpet' },
      pricingType: 'PerKg',
      serviceSnapshot: { id: SERVICE_ID, name: 'Dry clean' },
      taxPercent: 5,
      unitPrice: 20,
    });
    repository.create.mockImplementation((_scope, input) =>
      Promise.resolve(
        order({
          discount: input.discount,
          grandTotal: input.grandTotal,
          items: input.items.map((item, index) => ({ ...item, id: `${index}` })),
          outstandingAmount: input.outstandingAmount,
          subtotal: input.subtotal,
          tax: input.tax,
        }),
      ),
    );

    await service.create(scope(), {
      customerId: CUSTOMER_ID,
      discount: 10,
      items: [
        {
          discount: 5,
          itemCategoryId: CATEGORY_ID,
          serviceId: SERVICE_ID,
          tax: 999,
          weight: 2,
        },
      ],
      tax: 999,
    });

    expect(repository.create.mock.calls[0]?.[1]).toEqual(
      expect.objectContaining({
        grandTotal: 26.25,
        subtotal: 35,
        tax: 1.25,
        items: [expect.objectContaining({ lineTotal: 36.75, tax: 1.75, unitPrice: 20, weight: 2 })],
      }),
    );
  });

  it('rejects quantity for a weight-priced service', async () => {
    dependencies.quoteCatalog.mockResolvedValueOnce({
      itemCategorySnapshot: { id: CATEGORY_ID, name: 'Carpet' },
      pricingType: 'PerKg',
      serviceSnapshot: { id: SERVICE_ID, name: 'Dry clean' },
      taxPercent: 0,
      unitPrice: 20,
    });

    await expect(
      service.create(scope(), {
        customerId: CUSTOMER_ID,
        discount: 0,
        items: [
          {
            discount: 0,
            itemCategoryId: CATEGORY_ID,
            quantity: 2,
            serviceId: SERVICE_ID,
            tax: 0,
          },
        ],
        tax: 0,
      }),
    ).rejects.toThrow('PerKg services require weight');
  });

  it('rejects line and order discounts that exceed their applicable amounts', async () => {
    await expect(
      service.create(scope(), {
        customerId: CUSTOMER_ID,
        discount: 0,
        items: [
          {
            discount: 51,
            itemCategoryId: CATEGORY_ID,
            quantity: 1,
            serviceId: SERVICE_ID,
            tax: 0,
          },
        ],
        tax: 0,
      }),
    ).rejects.toThrow('Line discount cannot exceed');

    await expect(
      service.create(scope(), {
        customerId: CUSTOMER_ID,
        discount: 56,
        items: [
          {
            discount: 0,
            itemCategoryId: CATEGORY_ID,
            quantity: 1,
            serviceId: SERVICE_ID,
            tax: 0,
          },
        ],
        tax: 0,
      }),
    ).rejects.toThrow('Order discount cannot exceed');
  });

  it('rejects missing customers, invalid catalog lines, and forbidden create roles', async () => {
    dependencies.resolveCustomer.mockRejectedValueOnce(new NotFoundException('Customer not found'));
    await expect(
      service.create(scope(), {
        customerId: CUSTOMER_ID,
        discount: 0,
        items: [
          { discount: 0, itemCategoryId: CATEGORY_ID, quantity: 1, serviceId: SERVICE_ID, tax: 0 },
        ],
        tax: 0,
      }),
    ).rejects.toBeInstanceOf(NotFoundException);

    dependencies.resolveCustomer.mockResolvedValueOnce({
      customerId: CUSTOMER_ID,
      customerType: 'Regular',
      name: 'Customer',
    });
    dependencies.quoteCatalog.mockRejectedValueOnce(new BadRequestException('Invalid service'));
    await expect(
      service.create(scope(), {
        customerId: CUSTOMER_ID,
        discount: 0,
        items: [
          { discount: 0, itemCategoryId: CATEGORY_ID, quantity: 1, serviceId: SERVICE_ID, tax: 0 },
        ],
        tax: 0,
      }),
    ).rejects.toBeInstanceOf(BadRequestException);

    await expect(
      service.create(scope({ roleCode: 'staff' }), {
        customerId: CUSTOMER_ID,
        discount: 0,
        items: [
          { discount: 0, itemCategoryId: CATEGORY_ID, quantity: 1, serviceId: SERVICE_ID, tax: 0 },
        ],
        tax: 0,
      }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('lists with pagination/search/filter/sort and enforces branch scope', async () => {
    repository.list.mockResolvedValue({
      items: [order()],
      limit: 10,
      page: 2,
      total: 11,
      totalPages: 2,
    });
    const result = await service.list(scope(), {
      branchId: 'branch-a',
      limit: 10,
      page: 2,
      search: 'ORD-BRA',
      sortBy: 'orderNumber',
      sortDirection: SortDirection.Ascending,
      status: OrderStatus.RECEIVED,
    });
    expect(result.total).toBe(11);
    expect(result.totalPages).toBe(2);
    expect(repository.list.mock.calls[0]?.[1]).toEqual(
      expect.objectContaining({ page: 2, search: 'ORD-BRA', sortDirection: 1 }),
    );
    expect(() =>
      service.list(scope(), {
        branchId: 'branch-b',
        limit: 20,
        page: 1,
        sortBy: 'createdAt',
        sortDirection: SortDirection.Descending,
      }),
    ).toThrow(ForbiddenException);
  });

  it.each([
    ['PENDING', OrderStatus.RECEIVED],
    ['Processing', OrderStatus.IN_PROGRESS],
    ['READY', OrderStatus.READY],
    ['Completed', OrderStatus.DELIVERED],
  ])('maps frontend status filter %s to %s', async (inputStatus, expectedStatus) => {
    const pipe = new ValidationPipe({ transform: true, whitelist: true });
    const query = (await pipe.transform(
      { status: inputStatus },
      { metatype: OrderQueryDto, type: 'query' },
    )) as OrderQueryDto;

    expect(query.status).toBe(expectedStatus);
  });

  it('returns details only from the scoped repository and hides wrong tenant/branch records', async () => {
    repository.findById
      .mockResolvedValueOnce(
        order({
          assignment: {
            assignedBy: ACTOR_ID,
            assignedTo: STAFF_ID,
            createdAt: new Date('2026-08-13T10:00:00.000Z'),
            id: '64f0c18f7c4d2f0012ab3404',
            orderId: ORDER_ID,
            status: 'Assigned',
            updatedAt: new Date('2026-08-13T10:00:00.000Z'),
            version: 0,
          },
        }),
      )
      .mockResolvedValueOnce(null);
    await expect(service.get(scope(), ORDER_ID)).resolves.toMatchObject({
      assignment: { assignedTo: STAFF_ID, status: 'Assigned' },
      customerSnapshot: { name: 'Customer' },
      id: ORDER_ID,
      items: [expect.objectContaining({ serviceId: SERVICE_ID, unitPrice: 50 })],
      paymentStatus: OrderPaymentStatus.UNPAID,
    });
    await expect(
      service.get(scope({ tenantId: '64f0c18f7c4d2f0012ab3499' }), ORDER_ID),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('updates editable orders, preserves paid projection, and rejects processing orders', async () => {
    repository.findById.mockResolvedValueOnce(order());
    repository.update.mockResolvedValueOnce(
      order({ discount: 10, grandTotal: 100, outstandingAmount: 100 }),
    );
    await expect(service.update(scope(), ORDER_ID, { discount: 10 })).resolves.toMatchObject({
      discount: 10,
    });

    repository.findById.mockResolvedValueOnce(order({ status: OrderStatus.IN_PROGRESS }));
    await expect(service.update(scope(), ORDER_ID, { discount: 10 })).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('does not treat a deprecated client tax value as an editable financial field', async () => {
    repository.findById.mockResolvedValueOnce(order());

    await expect(service.update(scope(), ORDER_ID, { tax: 999 })).rejects.toBeInstanceOf(
      BadRequestException,
    );
    expect(repository.update.mock.calls).toHaveLength(0);
  });

  it('preserves paid amount when replacing items and recalculates the outstanding amount', async () => {
    repository.findById.mockResolvedValueOnce(order({ paidAmount: 25, outstandingAmount: 80 }));
    repository.update.mockImplementation((_scope, _id, _status, input) =>
      Promise.resolve(
        order({
          grandTotal: input.grandTotal,
          items: input.items.map((item, index) => ({ ...item, id: `${index}` })),
          outstandingAmount: input.outstandingAmount,
          paidAmount: input.paidAmount,
        }),
      ),
    );

    await service.update(scope(), ORDER_ID, {
      items: [
        {
          discount: 0,
          itemCategoryId: CATEGORY_ID,
          quantity: 3,
          serviceId: SERVICE_ID,
          tax: 0,
        },
      ],
    });

    expect(repository.update.mock.calls[0]?.[3]).toEqual(
      expect.objectContaining({ paidAmount: 25, outstandingAmount: 120 }),
    );
    expect(dependencies.validateCatalogReference.mock.calls).toContainEqual([
      expect.anything(),
      SERVICE_ID,
      CATEGORY_ID,
    ]);
    expect(dependencies.quoteCatalog.mock.calls).toHaveLength(0);
    expect(repository.update.mock.calls[0]?.[3].items[0]).toEqual(
      expect.objectContaining({ unitPrice: 50 }),
    );
  });

  it('rejects an edit that would reduce the total below the amount already paid', async () => {
    repository.findById.mockResolvedValueOnce(
      order({ grandTotal: 105, paidAmount: 100, outstandingAmount: 5 }),
    );

    await expect(service.update(scope(), ORDER_ID, { discount: 11 })).rejects.toThrow(
      'Grand total cannot be less than the amount already paid',
    );
    expect(repository.update.mock.calls).toHaveLength(0);
  });

  it('allows only the next lifecycle transition and writes transition audit/history', async () => {
    repository.findById.mockResolvedValue(order());
    repository.transition.mockResolvedValueOnce(order({ status: OrderStatus.IN_PROGRESS }));
    await expect(
      service.changeStatus(scope(), ORDER_ID, {
        note: 'Started',
        status: OrderStatus.IN_PROGRESS,
      }),
    ).resolves.toMatchObject({ status: OrderStatus.IN_PROGRESS });
    expect(repository.transition.mock.calls).toContainEqual([
      expect.anything(),
      ORDER_ID,
      OrderStatus.RECEIVED,
      OrderStatus.IN_PROGRESS,
      'Started',
    ]);
    await expect(
      service.changeStatus(scope(), ORDER_ID, { status: OrderStatus.READY }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('allows an accepted assignment to move into processing', async () => {
    repository.findById.mockResolvedValueOnce(
      order({ assignedTo: STAFF_ID, status: OrderStatus.ACCEPTED }),
    );
    repository.transition.mockResolvedValueOnce(
      order({ assignedTo: STAFF_ID, status: OrderStatus.IN_PROGRESS }),
    );

    await expect(
      service.changeStatus(
        scope({
          actorId: STAFF_ID,
          permissions: ['orders:read', 'orders:write'],
          roleCode: 'Staff',
        }),
        ORDER_ID,
        { status: OrderStatus.IN_PROGRESS },
      ),
    ).resolves.toMatchObject({ status: OrderStatus.IN_PROGRESS });
    expect(repository.transition).toHaveBeenCalledWith(
      expect.anything(),
      ORDER_ID,
      OrderStatus.ACCEPTED,
      OrderStatus.IN_PROGRESS,
      undefined,
    );
  });

  it('assigns only validated staff and restricts assignment by role', async () => {
    repository.findById.mockResolvedValue(order());
    repository.assign.mockResolvedValue(order({ assignedTo: STAFF_ID }));
    await expect(
      service.assign(scope(), ORDER_ID, { assignedTo: STAFF_ID }),
    ).resolves.toMatchObject({
      assignedTo: STAFF_ID,
    });
    expect(dependencies.assertStaffEligible.mock.calls.length).toBeGreaterThan(0);
    await expect(
      service.assign(scope({ roleCode: 'cashier' }), ORDER_ID, { assignedTo: STAFF_ID }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('rejects duplicate and terminal-order assignments before persistence', async () => {
    repository.findById.mockResolvedValueOnce(order({ assignedTo: STAFF_ID }));
    await expect(
      service.assign(scope(), ORDER_ID, { assignedTo: STAFF_ID }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(repository.assign.mock.calls).toHaveLength(0);

    repository.findById.mockResolvedValueOnce(order({ status: OrderStatus.DELIVERED }));
    await expect(
      service.assign(scope(), ORDER_ID, { assignedTo: STAFF_ID }),
    ).rejects.toBeInstanceOf(ConflictException);
    expect(repository.assign.mock.calls).toHaveLength(0);
  });

  it('allows Ready to be marked Delivered and returns the server delivery timestamp', async () => {
    const deliveryDate = new Date('2026-08-14T12:00:00.000Z');
    repository.findById.mockResolvedValueOnce(order({ status: OrderStatus.READY }));
    repository.transition.mockResolvedValueOnce(
      order({ deliveryDate, status: OrderStatus.DELIVERED }),
    );

    await expect(
      service.changeStatus(scope(), ORDER_ID, {
        note: 'Collected by customer',
        status: OrderStatus.DELIVERED,
      }),
    ).resolves.toMatchObject({ deliveryDate, status: OrderStatus.DELIVERED });
    expect(repository.transition.mock.calls).toContainEqual([
      expect.anything(),
      ORDER_ID,
      OrderStatus.READY,
      OrderStatus.DELIVERED,
      'Collected by customer',
    ]);
  });

  it('cancels non-terminal orders with a reason and rejects terminal cancellation', async () => {
    repository.findById.mockResolvedValueOnce(order());
    repository.transition.mockResolvedValueOnce(
      order({ cancelReason: 'Customer request', status: OrderStatus.CANCELLED }),
    );
    await expect(
      service.cancel(scope(), ORDER_ID, { reason: ' Customer request ' }),
    ).resolves.toMatchObject({ status: OrderStatus.CANCELLED });
    expect(repository.transition.mock.calls).toContainEqual([
      expect.anything(),
      ORDER_ID,
      OrderStatus.RECEIVED,
      OrderStatus.CANCELLED,
      'Customer request',
      'Customer request',
    ]);
    repository.findById.mockResolvedValueOnce(order({ status: OrderStatus.DELIVERED }));
    await expect(service.cancel(scope(), ORDER_ID, { reason: 'Too late' })).rejects.toBeInstanceOf(
      ConflictException,
    );
  });

  it('returns complete chronological status history after scoped order verification', async () => {
    repository.findById.mockResolvedValue(order());
    repository.history.mockResolvedValue([
      {
        changedBy: ACTOR_ID,
        id: '64f0c18f7c4d2f0012ab3403',
        newStatus: OrderStatus.RECEIVED,
        note: 'Order created',
        orderId: ORDER_ID,
        previousStatus: OrderStatus.DRAFT,
        timestamp: new Date(),
      },
    ]);
    await expect(service.history(scope(), ORDER_ID)).resolves.toHaveLength(1);
  });

  it('keeps order statistics in authenticated branch scope and restricts staff to assignments', async () => {
    repository.statistics.mockResolvedValue({
      outstandingCustomerCount: 0,
      outstandingTotal: 0,
      statusBreakdown: {},
      todayOrders: 0,
      totalOrders: 0,
      yesterdayOrders: 0,
    });

    await service.statistics(scope({ roleCode: 'Owner' }));
    await service.statistics(scope({ roleCode: 'Branch Manager' }), CUSTOMER_ID);
    await service.statistics(scope({ roleCode: 'Staff' }));

    expect(repository.statistics.mock.calls).toEqual([
      [expect.objectContaining({ branchId: 'branch-a', tenantId: TENANT_ID }), {}],
      [
        expect.objectContaining({ branchId: 'branch-a', tenantId: TENANT_ID }),
        { customerId: CUSTOMER_ID },
      ],
      [
        expect.objectContaining({ branchId: 'branch-a', tenantId: TENANT_ID }),
        { assignedTo: ACTOR_ID },
      ],
    ]);
  });

  it('rejects invalid create DTOs through the project validation pipe', async () => {
    const pipe = new ValidationPipe({
      forbidNonWhitelisted: true,
      transform: true,
      whitelist: true,
    });
    await expect(
      pipe.transform(
        { customerId: 'bad-id', items: [] },
        { metatype: CreateOrderDto, type: 'body' },
      ),
    ).rejects.toBeInstanceOf(BadRequestException);

    await expect(
      pipe.transform(
        {
          customerId: CUSTOMER_ID,
          grandTotal: 1,
          items: [
            {
              discount: 0,
              itemCategoryId: CATEGORY_ID,
              quantity: 1,
              serviceId: SERVICE_ID,
              tax: 0,
            },
          ],
          subtotal: 1,
        },
        { metatype: CreateOrderDto, type: 'body' },
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  describe('acceptAssignment & rejectAssignment', () => {
    it('allows assigned staff to accept assignment', async () => {
      const existingOrder = order({ assignedTo: STAFF_ID });
      repository.findById.mockResolvedValue(existingOrder);
      repository.acceptAssignment.mockResolvedValue({
        ...existingOrder,
        assignment: {
          assignedBy: ACTOR_ID,
          assignedTo: STAFF_ID,
          createdAt: new Date(),
          id: 'assign-1',
          orderId: ORDER_ID,
          status: 'Accepted',
          updatedAt: new Date(),
          version: 0,
        },
      });

      const staffScope = scope({
        actorId: STAFF_ID,
        permissions: ['orders:read', 'orders:write'],
        roleCode: 'Staff',
      });

      const result = await service.acceptAssignment(staffScope, ORDER_ID);
      expect(result.assignment?.status).toBe('Accepted');
      expect(repository.acceptAssignment).toHaveBeenCalledWith(staffScope, ORDER_ID);
    });

    it('allows assigned staff to reject assignment and clear worker', async () => {
      const existingOrder = order({ assignedTo: STAFF_ID });
      repository.findById.mockResolvedValue(existingOrder);
      repository.rejectAssignment.mockResolvedValue({
        ...existingOrder,
        assignedTo: undefined,
        assignment: {
          assignedBy: ACTOR_ID,
          assignedTo: STAFF_ID,
          createdAt: new Date(),
          id: 'assign-1',
          orderId: ORDER_ID,
          status: 'Rejected',
          updatedAt: new Date(),
          version: 0,
        },
      });

      const staffScope = scope({
        actorId: STAFF_ID,
        permissions: ['orders:read', 'orders:write'],
        roleCode: 'Staff',
      });

      const result = await service.rejectAssignment(staffScope, ORDER_ID, 'Not available');
      expect(result.assignedTo).toBeUndefined();
      expect(result.assignment?.status).toBe('Rejected');
      expect(repository.rejectAssignment).toHaveBeenCalledWith(
        staffScope,
        ORDER_ID,
        'Not available',
      );
    });

    it('forbids unassigned staff from accepting or rejecting assignment', async () => {
      const existingOrder = order({ assignedTo: 'another-staff-id' });
      repository.findById.mockResolvedValue(existingOrder);

      const unauthorizedStaffScope = scope({
        actorId: STAFF_ID,
        permissions: ['orders:read', 'orders:write'],
        roleCode: 'Staff',
      });

      await expect(service.acceptAssignment(unauthorizedStaffScope, ORDER_ID)).rejects.toThrow();
      await expect(service.rejectAssignment(unauthorizedStaffScope, ORDER_ID)).rejects.toThrow();
    });
  });
});
