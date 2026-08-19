import { ForbiddenException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { HttpOrderDependencies } from '../src/order/order.integrations';
import type { OrderScope } from '../src/order/order.types';

const scope: OrderScope = {
  actorId: '64f0c18f7c4d2f0012ab34aa',
  authorization: 'Bearer valid-token',
  branchId: 'branch-a',
  permissions: ['orders:write'],
  roleCode: 'tenant_owner',
  tenantId: '64f0c18f7c4d2f0012ab34bb',
};

describe('Order Branch integration', () => {
  const dependencies = new HttpOrderDependencies(
    new ConfigService({ BRANCH_SERVICE_BASE_URL: 'http://branch.test' }),
  );
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('resolves the exact authenticated active branch instead of paginating a list', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            data: { branchId: scope.branchId, code: 'MAIN', status: 'active' },
          }),
          { status: 200 },
        ),
      ),
    ) as typeof fetch;

    await expect(dependencies.resolveBranch(scope)).resolves.toEqual({
      branchId: 'branch-a',
      code: 'MAIN',
    });
    expect(global.fetch).toHaveBeenCalledWith(
      'http://branch.test/v1/branches/branch-a',
      expect.objectContaining({
        headers: {
          authorization: scope.authorization,
          'x-branch-id': scope.branchId,
        },
      }),
    );
  });

  it('still rejects an inactive branch', async () => {
    global.fetch = jest.fn(() =>
      Promise.resolve(
        new Response(
          JSON.stringify({
            data: { branchId: scope.branchId, code: 'MAIN', status: 'inactive' },
          }),
          { status: 200 },
        ),
      ),
    ) as typeof fetch;

    await expect(dependencies.resolveBranch(scope)).rejects.toBeInstanceOf(ForbiddenException);
  });
});
