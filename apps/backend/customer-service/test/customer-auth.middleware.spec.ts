import { ConfigService } from '@nestjs/config';
import { ForbiddenException, UnauthorizedException } from '@nestjs/common';

import { CustomerAuthenticationMiddleware } from '../src/customer/customer-auth.middleware';
import type { CustomerRequest } from '../src/customer/customer.guard';

interface TestRequest extends CustomerRequest {
  headers: Record<string, string>;
}

describe('CustomerAuthenticationMiddleware', () => {
  const middleware = new CustomerAuthenticationMiddleware(
    new ConfigService({ AUTH_SERVICE_BASE_URL: 'http://auth.test/api' }),
  );
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  it('uses Auth Service to populate trusted tenant and selected branch context', async () => {
    global.fetch = jest.fn().mockResolvedValue(
      new Response(
        JSON.stringify({
          data: {
            actorId: '64f0c18f7c4d2f0012ab34aa',
            kind: 'tenant',
            tenantId: '64f0c18f7c4d2f0012ab34bb',
            branchId: 'branch-b',
          },
        }),
        { status: 200, headers: { 'content-type': 'application/json' } },
      ),
    ) as typeof fetch;
    const request: TestRequest = {
      headers: { authorization: 'Bearer valid-token', 'x-branch-id': 'branch-b' },
    };
    const next = jest.fn();

    await middleware.use(request, {}, next);

    const fetchMock = jest.mocked(global.fetch);
    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(fetchMock.mock.calls[0][0]).toBe('http://auth.test/api/v1/auth/context');
    expect(fetchMock.mock.calls[0][1]?.headers).toEqual({
      authorization: 'Bearer valid-token',
      'x-branch-id': 'branch-b',
    });
    expect(request.trustedContext).toMatchObject({
      tenantId: '64f0c18f7c4d2f0012ab34bb',
      branchId: 'branch-b',
    });
    expect(next).toHaveBeenCalledTimes(1);
  });

  it('leaves a missing token for the scope guard to reject', async () => {
    const request: TestRequest = { headers: {} };
    const next = jest.fn();
    await middleware.use(request, {}, next);
    expect(request.trustedContext).toBeUndefined();
    expect(next).toHaveBeenCalledTimes(1);
  });

  it('rejects invalid authentication and unauthorized branch selection', async () => {
    global.fetch = jest
      .fn()
      .mockResolvedValueOnce(new Response('', { status: 401 }))
      .mockResolvedValueOnce(new Response('', { status: 403 })) as typeof fetch;
    const request: TestRequest = { headers: { authorization: 'Bearer invalid' } };
    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(ForbiddenException);
  });
});
