import { UnauthorizedException } from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';

import { CatalogAuthenticationMiddleware } from '../src/catalog/catalog-auth.middleware';
import type { CatalogRequest } from '../src/catalog/catalog.guard';

const ACTOR_ID = '64f0c18f7c4d2f0012ab34ab';
const TENANT_ID = '64f0c18f7c4d2f0012ab34aa';

function token(): string {
  const payload = Buffer.from(
    JSON.stringify({ claims: { userId: ACTOR_ID, tenantId: TENANT_ID, roleCode: 'tenant_owner' } }),
  ).toString('base64url');
  return `header.${payload}.signature`;
}

describe('CatalogAuthenticationMiddleware', () => {
  const config = { get: jest.fn().mockReturnValue('http://auth/api') } as unknown as ConfigService;
  let originalFetch: typeof global.fetch;

  beforeEach(() => {
    originalFetch = global.fetch;
  });
  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('rejects missing bearer authentication', async () => {
    const middleware = new CatalogAuthenticationMiddleware(config);
    await expect(middleware.use({ headers: {} }, {}, jest.fn())).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('uses Auth Service context and never accepts tenant scope from request input', async () => {
    global.fetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: () =>
        Promise.resolve({
          data: { kind: 'tenant', actorId: ACTOR_ID, tenantId: TENANT_ID, branchId: 'branch-a' },
        }),
    });
    const request: CatalogRequest = {
      headers: { authorization: `Bearer ${token()}`, 'x-branch-id': 'branch-a' },
    };
    const next = jest.fn();
    await new CatalogAuthenticationMiddleware(config).use(request, {}, next);
    expect(request.trustedContext).toEqual(
      expect.objectContaining({
        actorId: ACTOR_ID,
        tenantId: TENANT_ID,
        branchId: 'branch-a',
        roleCode: 'tenant_owner',
      }),
    );
    expect(next).toHaveBeenCalledTimes(1);
  });
});
