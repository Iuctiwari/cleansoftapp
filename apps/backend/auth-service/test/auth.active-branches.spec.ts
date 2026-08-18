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
    );

    const identity = await repository.findIdentity('tenant', owner.email, tenant.slug);

    expect(branchModel.find).toHaveBeenCalledWith({ tenantId: tenant.tenantId, status: 'active' });
    expect(identity?.branches).toEqual([
      {
        branchId: branch.branchId,
        branchCode: 'head-office',
        branchName: branch.branchName,
      },
    ]);
  });
});
