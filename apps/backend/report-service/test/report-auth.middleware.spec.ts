import 'reflect-metadata';

import { ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { ReportAuthenticationMiddleware } from '../src/report/report-auth.middleware';
import type { ReportRequest } from '../src/report/report.guard';

const ACTOR_ID = '64f0c18f7c4d2f0012ab34bb';
const TENANT_ID = '64f0c18f7c4d2f0012ab34aa';

function token(): string {
  const payload = Buffer.from(
    JSON.stringify({
      claims: {
        permissions: ['view:reports'],
        roleCode: 'cashier',
        tenantId: TENANT_ID,
        userId: ACTOR_ID,
      },
    }),
  ).toString('base64url');
  return `header.${payload}.signature`;
}

function request(branchId?: string): ReportRequest {
  return {
    headers: {
      authorization: `Bearer ${token()}`,
      ...(branchId ? { 'x-branch-id': branchId } : {}),
    },
  };
}

describe('ReportAuthenticationMiddleware', () => {
  const middleware = new ReportAuthenticationMiddleware(
    new ConfigService({ AUTH_SERVICE_BASE_URL: 'http://auth.test/api' }),
  );

  afterEach(() => jest.restoreAllMocks());

  it('rejects missing authentication before contacting Auth Service', async () => {
    const fetchSpy = jest.spyOn(globalThis, 'fetch');
    await expect(
      middleware.use({ headers: { 'x-branch-id': 'branch-a' } }, {}, jest.fn()),
    ).rejects.toThrow(new UnauthorizedException('A valid bearer token is required'));
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('rejects a missing branch before contacting Auth Service', async () => {
    const fetchSpy = jest.spyOn(globalThis, 'fetch');
    await expect(middleware.use(request(), {}, jest.fn())).rejects.toThrow(
      new UnauthorizedException('An active branch is required'),
    );
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('uses only the tenant and branch validated by Auth Service', async () => {
    jest.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(
        JSON.stringify({
          data: { actorId: ACTOR_ID, branchId: 'branch-a', kind: 'tenant', tenantId: TENANT_ID },
        }),
        { status: 200 },
      ),
    );
    const scopedRequest = request('branch-a');
    const next = jest.fn();

    await middleware.use(scopedRequest, {}, next);

    expect(scopedRequest.trustedContext).toEqual(
      expect.objectContaining({ branchId: 'branch-a', tenantId: TENANT_ID }),
    );
    expect(next).toHaveBeenCalledTimes(1);
    expect(globalThis.fetch).toHaveBeenCalledWith(
      'http://auth.test/api/v1/auth/context',
      expect.objectContaining({
        headers: expect.objectContaining({ 'x-branch-id': 'branch-a' }) as unknown,
      }),
    );
  });

  it('rejects a context that does not match the selected branch', async () => {
    jest.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(
        JSON.stringify({
          data: { actorId: ACTOR_ID, branchId: 'branch-b', kind: 'tenant', tenantId: TENANT_ID },
        }),
        { status: 200 },
      ),
    );
    await expect(middleware.use(request('branch-a'), {}, jest.fn())).rejects.toThrow(
      UnauthorizedException,
    );
  });

  it('preserves Auth Service branch-access denial', async () => {
    jest.spyOn(globalThis, 'fetch').mockResolvedValue(new Response(null, { status: 403 }));
    await expect(middleware.use(request('branch-a'), {}, jest.fn())).rejects.toThrow(
      ForbiddenException,
    );
  });
});
