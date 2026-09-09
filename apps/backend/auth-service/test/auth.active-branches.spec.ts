import { MongoAuthRepository } from '../src/auth/auth.mongo.repository';

function query<T>(value: T): { lean: () => { exec: () => Promise<T> } } {
  return { lean: () => ({ exec: () => Promise.resolve(value) }) };
}

describe('MongoAuthRepository active branch identity', () => {
  it('only includes active tenant branches in authenticated branch scope', async () => {
    const tenant = { tenantId: 'tenant-a', slug: 'tenant-a', status: 'Active' };
    const owner = {
      userId: 'owner-a',
      tenantId: 'tenant-a',
      slug: 'tenant-a',
      email: 'owner@example.test',
      mobileNumber: '9876543210',
      displayName: 'Owner',
      tenantName: 'Tenant A',
      passwordHash: 'hash',
      roleCode: 'tenant_owner',
      permissions: [],
      status: 'active',
      accessVersion: 1,
    };
    const branch = {
      branchId: 'active-branch',
      branchName: 'Head Office',
      isHeadOffice: true,
    };
    const tenantModel = { findOne: jest.fn(() => query(tenant)) };
    const ownerModel = { findOne: jest.fn(() => query(owner)) };
    const branchModel = { find: jest.fn(() => query([branch])) };
    const repository = new MongoAuthRepository(
      undefined as never,
      undefined as never,
      undefined as never,
      undefined as never,
      { findOne: jest.fn(() => query(null)) } as never,
      ownerModel as never,
      tenantModel as never,
      branchModel as never,
      undefined as never,
      undefined as never,
    );

    const identity = await repository.findIdentity('tenant', owner.email);

    expect(branchModel.find).toHaveBeenCalledWith({
      tenantId: tenant.tenantId,
      status: { $in: ['active', 'Active'] },
    });
    expect(identity?.branches).toEqual([
      {
        branchId: branch.branchId,
        branchCode: 'head-office',
        branchName: branch.branchName,
      },
    ]);
  });

  it('includes branches with uppercase Active status for Owner login', async () => {
    const tenant = { tenantId: 'tenant-b', slug: 'tenant-b', status: 'Active' };
    const owner = {
      userId: 'owner-b',
      tenantId: 'tenant-b',
      slug: 'tenant-b',
      email: 'owner-b@example.test',
      mobileNumber: '9876543211',
      displayName: 'Owner B',
      tenantName: 'Tenant B',
      passwordHash: 'hash',
      roleCode: 'tenant_owner',
      permissions: [],
      status: 'active',
      accessVersion: 1,
    };
    const branch = {
      branchId: 'branch-b-1',
      branchName: 'Main Branch',
      isHeadOffice: true,
      status: 'Active',
    };
    const tenantModel = { findOne: jest.fn(() => query(tenant)) };
    const ownerModel = { findOne: jest.fn(() => query(owner)) };
    const branchModel = { find: jest.fn(() => query([branch])) };
    const repository = new MongoAuthRepository(
      undefined as never,
      undefined as never,
      undefined as never,
      undefined as never,
      { findOne: jest.fn(() => query(null)) } as never,
      ownerModel as never,
      tenantModel as never,
      branchModel as never,
      undefined as never,
      undefined as never,
    );

    const identity = await repository.findIdentity('tenant', owner.email);

    expect(ownerModel.findOne).toHaveBeenCalledWith({
      $or: [{ email: owner.email }, { mobileNumber: owner.email }],
    });
    expect(tenantModel.findOne).toHaveBeenCalledWith({ tenantId: owner.tenantId });
    expect(identity?.tenantId).toBe('tenant-b');
    expect(identity?.branches).toEqual([
      {
        branchId: 'branch-b-1',
        branchCode: 'main-branch',
        branchName: 'Main Branch',
      },
    ]);
  });
});
