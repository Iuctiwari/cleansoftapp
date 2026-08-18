import { ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { OrderAuthenticationMiddleware } from '../src/order/order-auth.middleware';
import type { OrderRequest } from '../src/order/order.guard';

const ACTOR_ID = '64f0c18f7c4d2f0012ab34aa';
const TENANT_ID = '64f0c18f7c4d2f0012ab34bb';

function token(): string {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(
    JSON.stringify({
      claims: {
        permissions: ['orders:read', 'orders:write'],
        roleCode: 'tenant_owner',
        tenantId: TENANT_ID,
        userId: ACTOR_ID,
      },
    }),
  ).toString('base64url');
  return `${header}.${payload}.auth-service-validates-signature`;
}

describe('OrderAuthenticationMiddleware', () => {
  const middleware = new OrderAuthenticationMiddleware(
    new ConfigService({ AUTH_SERVICE_BASE_URL: 'http://auth.test/api' }),
  );
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('rejects an unauthenticated request', async () => {
    const request: OrderRequest = { headers: {} };
    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('uses centralized auth context and derives trusted tenant/branch/RBAC scope', async () => {
    global.fetch = jest.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          data: {
            actorId: ACTOR_ID,
            branchId: 'branch-a',
            kind: 'tenant',
            tenantId: TENANT_ID,
          },
        }),
        { status: 200 },
      ),
    ) as typeof fetch;
    const request: OrderRequest = {
      headers: { authorization: `Bearer ${token()}`, 'x-branch-id': 'branch-a' },
    };
    const next = jest.fn();

    await middleware.use(request, {}, next);

    const fetchMock = jest.mocked(global.fetch);
    expect(fetchMock.mock.calls[0]?.[0]).toBe('http://auth.test/api/v1/auth/context');
    expect(fetchMock.mock.calls[0]?.[1]?.headers).toEqual(
      expect.objectContaining({ 'x-branch-id': 'branch-a' }),
    );
    expect(request.trustedContext).toMatchObject({
      actorId: ACTOR_ID,
      branchId: 'branch-a',
      permissions: ['orders:read', 'orders:write'],
      roleCode: 'tenant_owner',
      tenantId: TENANT_ID,
    });
    expect(next).toHaveBeenCalledTimes(1);
  });

  it('rejects a forbidden branch selected by centralized authentication', async () => {
    global.fetch = jest.fn().mockResolvedValue(new Response('', { status: 403 })) as typeof fetch;
    const request: OrderRequest = { headers: { authorization: `Bearer ${token()}` } };
    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(ForbiddenException);
  });
});
