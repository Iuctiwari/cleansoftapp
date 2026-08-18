import {
  AssignmentMongooseSchema,
  CounterMongooseSchema,
  OrderMongooseSchema,
} from '../src/order/order.schema';

function namedIndex(
  indexes: ReturnType<typeof OrderMongooseSchema.indexes>,
  name: string,
): ReturnType<typeof OrderMongooseSchema.indexes>[number] | undefined {
  return indexes.find(([, options]) => options.name === name);
}

describe('Order MongoDB index contract', () => {
  it('keeps order numbers unique inside a tenant and branch', () => {
    const index = namedIndex(OrderMongooseSchema.indexes(), 'orders_tenant_branch_number_unique');

    expect(index?.[0]).toEqual({ tenantId: 1, branchId: 1, orderNumber: 1 });
    expect(index?.[1].unique).toBe(true);
  });

  it('keeps one counter per tenant, branch, and counter type', () => {
    const index = namedIndex(CounterMongooseSchema.indexes(), 'counters_tenant_branch_type_unique');

    expect(index?.[0]).toEqual({ tenantId: 1, branchId: 1, type: 1 });
    expect(index?.[1].unique).toBe(true);
  });

  it('keeps one current assignment per scoped order', () => {
    const index = namedIndex(
      AssignmentMongooseSchema.indexes(),
      'assignments_tenant_branch_order_unique',
    );

    expect(index?.[0]).toEqual({ tenantId: 1, branchId: 1, orderId: 1 });
    expect(index?.[1].unique).toBe(true);
  });
});
