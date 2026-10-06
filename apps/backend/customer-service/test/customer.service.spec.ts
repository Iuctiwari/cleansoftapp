import 'reflect-metadata';

import { BadRequestException, NotFoundException, ValidationPipe } from '@nestjs/common';
import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { Types } from 'mongoose';

import {
  CreateCustomerDto,
  ListCustomersQueryDto,
  UpdateCustomerDto,
} from '../src/customer/customer.dto';
import {
  CustomerMongooseSchema,
  CustomerSource,
  CustomerType,
} from '../src/customer/customer.mongoose.schema';
import { CustomerService } from '../src/customer/customer.service';
import type {
  CreateCustomerFields,
  CustomerListQuery,
  CustomerMutableFields,
  CustomerPage,
  CustomerRecord,
  CustomerRepository,
  CustomerScope,
  CustomerStatistics,
} from '../src/customer/customer.types';

class InMemoryCustomerRepository implements CustomerRepository {
  readonly records: CustomerRecord[] = [];
  readonly deletedIds = new Set<string>();

  linkOnlineCustomer(): never {
    throw new Error('not used by these tests');
  }

  countForTenant(tenantId: string): Promise<number> {
    return Promise.resolve(
      this.records.filter((r) => r.tenantId === tenantId && !this.deletedIds.has(r.id)).length,
    );
  }

  create(scope: CustomerScope, input: CreateCustomerFields): Promise<CustomerRecord> {
    const now = new Date();
    const record: CustomerRecord = {
      id: new Types.ObjectId().toHexString(),
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      name: input.name,
      mobile: input.mobile ?? undefined,
      email: input.email ?? undefined,
      address: input.address ?? undefined,
      customerType: input.customerType,
      joiningDate: input.joiningDate ?? now,
      totalOrders: 0,
      totalSpent: 0,
      outstandingBalance: 0,
      lastOrderDate: null,
      source: CustomerSource.SHOP,
      createdAt: now,
      updatedAt: now,
    };
    this.records.push(record);
    return Promise.resolve(record);
  }

  findById(scope: CustomerScope, id: string): Promise<CustomerRecord | null> {
    return Promise.resolve(
      this.records.find(
        (record) =>
          record.id === id &&
          !this.deletedIds.has(record.id) &&
          record.tenantId === scope.tenantId &&
          record.branchId === scope.branchId,
      ) ?? null,
    );
  }

  list(scope: CustomerScope, query: CustomerListQuery): Promise<CustomerPage> {
    const search = query.search?.toLowerCase();
    const matches = this.records.filter(
      (record) =>
        record.tenantId === scope.tenantId &&
        record.branchId === scope.branchId &&
        !this.deletedIds.has(record.id) &&
        (!search || record.name.toLowerCase().includes(search) || record.mobile?.includes(search)),
    );
    const start = (query.page - 1) * query.limit;
    return Promise.resolve({
      items: matches.slice(start, start + query.limit),
      total: matches.length,
      page: query.page,
      limit: query.limit,
    });
  }

  statistics(scope: CustomerScope): Promise<CustomerStatistics> {
    const matches = this.records.filter(
      (record) =>
        record.tenantId === scope.tenantId &&
        record.branchId === scope.branchId &&
        !this.deletedIds.has(record.id),
    );
    return Promise.resolve({
      total: matches.length,
      active: matches.length,
      outstanding: matches.reduce((sum, record) => sum + record.outstandingBalance, 0),
    });
  }

  async update(
    scope: CustomerScope,
    id: string,
    input: CustomerMutableFields,
  ): Promise<CustomerRecord | null> {
    const existing = await this.findById(scope, id);
    if (!existing) return null;
    const updated: CustomerRecord = { ...existing, updatedAt: new Date() };
    for (const [field, value] of Object.entries(input)) {
      if (value === null) delete (updated as unknown as Record<string, unknown>)[field];
      else (updated as unknown as Record<string, unknown>)[field] = value;
    }
    this.records.splice(this.records.indexOf(existing), 1, updated);
    return updated;
  }

  async softDelete(scope: CustomerScope, id: string): Promise<boolean> {
    const existing = await this.findById(scope, id);
    if (!existing) return false;
    this.deletedIds.add(id);
    return true;
  }
}

const actorId = new Types.ObjectId().toHexString();
const tenantOne = new Types.ObjectId().toHexString();
const tenantTwo = new Types.ObjectId().toHexString();
const scope: CustomerScope = {
  actorId,
  tenantId: tenantOne,
  branchId: 'branch-one',
  roleCode: 'Owner',
  permissions: [],
};

function createDto(name: string, mobile: string): CreateCustomerDto {
  return plainToInstance(CreateCustomerDto, {
    name,
    mobile,
    customerType: CustomerType.REGULAR,
  });
}

describe('CustomerService', () => {
  let repository: InMemoryCustomerRepository;
  let service: CustomerService;

  beforeEach(() => {
    repository = new InMemoryCustomerRepository();
    service = new CustomerService(repository);
  });

  it('creates a customer with protected aggregate defaults', async () => {
    const customer = await service.create(scope, createDto('Asha', '+919876543210'));

    expect(customer).toMatchObject({
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      totalOrders: 0,
      totalSpent: 0,
      outstandingBalance: 0,
      lastOrderDate: null,
    });
    expect(customer.joiningDate).toBeInstanceOf(Date);
  });

  it('returns only the requested page and limit', async () => {
    await service.create(scope, createDto('One', '+919876543201'));
    await service.create(scope, createDto('Two', '+919876543202'));
    await service.create(scope, createDto('Three', '+919876543203'));

    const result = await service.list(
      scope,
      plainToInstance(ListCustomersQueryDto, { page: 2, limit: 2 }),
    );
    expect(result).toMatchObject({ total: 3, page: 2, limit: 2 });
    expect(result.items).toHaveLength(1);
  });

  it('returns unfiltered branch-wide statistics', async () => {
    await service.create(scope, createDto('One', '+919876543211'));
    await service.create(scope, createDto('Two', '+919876543212'));
    const statistics = await service.statistics(scope);
    expect(statistics).toEqual({ total: 2, active: 2, outstanding: 0 });
  });

  it('searches customer names case-insensitively', async () => {
    await service.create(scope, createDto('Anita Sharma', '+919876543204'));
    await service.create(scope, createDto('Rahul Rao', '+919876543205'));

    const result = await service.list(
      scope,
      plainToInstance(ListCustomersQueryDto, { search: 'SHARMA' }),
    );
    expect(result.items.map((item) => item.name)).toEqual(['Anita Sharma']);
  });

  it('searches mobile numbers using partial and suffix values', async () => {
    await service.create(scope, createDto('Anita', '+919876543204'));

    const result = await service.list(
      scope,
      plainToInstance(ListCustomersQueryDto, { search: '3204' }),
    );
    expect(result.items).toHaveLength(1);
  });

  it('gets customer details within the current scope', async () => {
    const created = await service.create(scope, createDto('Asha', '+919876543206'));
    await expect(service.getById(scope, created.id)).resolves.toEqual(created);
  });

  it('updates only mutable profile fields', async () => {
    const created = await service.create(scope, createDto('Asha', '+919876543207'));
    const updated = await service.update(
      scope,
      created.id,
      plainToInstance(UpdateCustomerDto, { name: 'Asha Rao', customerType: CustomerType.VIP }),
    );
    expect(updated).toMatchObject({ name: 'Asha Rao', customerType: CustomerType.VIP });
    expect(updated.totalOrders).toBe(0);
  });

  it('clears optional profile fields when null is supplied', async () => {
    const created = await service.create(
      scope,
      plainToInstance(CreateCustomerDto, {
        name: 'Asha',
        mobile: '+919876543207',
        email: 'asha@example.com',
        address: 'Old address',
        customerType: CustomerType.REGULAR,
      }),
    );
    const updated = await service.update(
      scope,
      created.id,
      plainToInstance(UpdateCustomerDto, { email: null, address: null }),
    );
    expect(updated.email).toBeUndefined();
    expect(updated.address).toBeUndefined();
  });

  it('does not reveal a customer from another tenant', async () => {
    const created = await service.create(scope, createDto('Asha', '+919876543208'));
    await expect(
      service.getById({ ...scope, tenantId: tenantTwo }, created.id),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('does not reveal a customer from another branch', async () => {
    const created = await service.create(scope, createDto('Asha', '+919876543209'));
    await expect(
      service.getById({ ...scope, branchId: 'branch-two' }, created.id),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('allows Staff to read/create but rejects update and delete', async () => {
    const staffScope: CustomerScope = {
      ...scope,
      roleCode: 'Staff',
      permissions: ['customers:read', 'customers:write'],
    };
    const created = await service.create(staffScope, createDto('Staff Customer', '+919876543210'));
    await expect(service.getById(staffScope, created.id)).resolves.toEqual(created);
    await expect(
      service.update(
        staffScope,
        created.id,
        plainToInstance(UpdateCustomerDto, { name: 'Forbidden Update' }),
      ),
    ).rejects.toThrow('Customer management permission is required');
    await expect(service.delete(staffScope, created.id)).rejects.toThrow(
      'Customer delete permission is required',
    );
  });

  it('allows Branch Manager customer management in the authenticated branch', async () => {
    const managerScope: CustomerScope = {
      ...scope,
      roleCode: 'Branch Manager',
      permissions: ['customers:read', 'customers:write', 'customers:delete'],
    };
    const created = await service.create(managerScope, createDto('Managed', '+919876543211'));
    await expect(
      service.update(
        managerScope,
        created.id,
        plainToInstance(UpdateCustomerDto, { name: 'Updated' }),
      ),
    ).resolves.toEqual(expect.objectContaining({ name: 'Updated' }));
    await expect(service.delete(managerScope, created.id)).resolves.toBeUndefined();
  });

  it('rejects invalid customer data', async () => {
    const invalid = plainToInstance(CreateCustomerDto, {
      name: '',
      mobile: 'invalid',
      email: 'invalid',
      customerType: 'Unknown',
    });
    expect(await validate(invalid)).not.toHaveLength(0);
  });

  it('rejects protected aggregate fields through the whitelist validation pipe', async () => {
    const pipe = new ValidationPipe({
      forbidNonWhitelisted: true,
      transform: true,
      whitelist: true,
    });
    await expect(
      pipe.transform(
        { name: 'Allowed', totalSpent: 999, tenantId: tenantTwo },
        { type: 'body', metatype: UpdateCustomerDto },
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('requires mobile when converting a walk-in customer to registered', async () => {
    const walkIn = await service.create(
      scope,
      plainToInstance(CreateCustomerDto, {
        name: 'Walk-in',
        customerType: CustomerType.WALK_IN,
      }),
    );
    await expect(
      service.update(
        scope,
        walkIn.id,
        plainToInstance(UpdateCustomerDto, { customerType: CustomerType.REGULAR }),
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('soft-deletes a customer and excludes it from details, list, and search', async () => {
    const created = await service.create(scope, createDto('Delete Me', '+919876543299'));

    await expect(service.delete(scope, created.id)).resolves.toBeUndefined();
    await expect(service.getById(scope, created.id)).rejects.toBeInstanceOf(NotFoundException);

    const list = await service.list(scope, plainToInstance(ListCustomersQueryDto, {}));
    const search = await service.list(
      scope,
      plainToInstance(ListCustomersQueryDto, { search: 'Delete Me' }),
    );
    expect(list.items).not.toContainEqual(expect.objectContaining({ id: created.id }));
    expect(search.items).toHaveLength(0);
    expect(repository.records).toContainEqual(expect.objectContaining({ id: created.id }));
  });

  it('does not soft-delete a customer from another tenant or branch', async () => {
    const created = await service.create(scope, createDto('Scoped', '+919876543298'));

    await expect(
      service.delete({ ...scope, tenantId: tenantTwo }, created.id),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(
      service.delete({ ...scope, branchId: 'branch-two' }, created.id),
    ).rejects.toBeInstanceOf(NotFoundException);
    await expect(service.getById(scope, created.id)).resolves.toEqual(created);
  });
});

describe('Customer soft-delete schema', () => {
  it('registers the shared soft-delete fields and active tenant index', () => {
    expect(CustomerMongooseSchema.path('isDeleted')).toBeDefined();
    expect(CustomerMongooseSchema.path('deletedAt')).toBeDefined();
    expect(CustomerMongooseSchema.path('deletedBy')).toBeDefined();
    expect(CustomerMongooseSchema.path('isDeleted').options.default).toBe(false);
    expect(CustomerMongooseSchema.indexes()).toContainEqual(
      expect.arrayContaining([expect.objectContaining({ tenantId: 1, isDeleted: 1 })]),
    );
  });
});
