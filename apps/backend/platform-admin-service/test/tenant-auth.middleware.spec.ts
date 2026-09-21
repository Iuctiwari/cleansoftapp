import { ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

import {
  AdminRole,
  PLATFORM_ADMIN_ACCESS_TOKEN_TYPE,
  PLATFORM_ADMIN_TOKEN_AUDIENCE,
  PLATFORM_ADMIN_TOKEN_ISSUER,
} from '../src/admin-auth/admin-auth.types';
import { TenantAuthMiddleware } from '../src/tenant-config/tenant-auth.middleware';
import type { TenantConfigRequest } from '../src/tenant-config/tenant-config.guard-types';

function buildConfigService(): ConfigService {
  return { get: () => 'http://localhost:3001/api' } as unknown as ConfigService;
}

function buildRequest(authorization?: string): TenantConfigRequest {
  return { headers: authorization ? { authorization } : {} };
}

function mockFetchOnce(response: Partial<Response> & { ok: boolean; status: number }): void {
  (global as unknown as { fetch: jest.Mock }).fetch = jest.fn().mockResolvedValue(response);
}

// A real tenant JWT-shaped token whose payload matches what the existing
// AuthenticationContextMiddleware pattern reads (claims.userId/tenantId/roleCode).
function buildTenantAccessToken(claims: {
  userId: string;
  tenantId: string;
  roleCode: string;
  permissions?: string[];
}): string {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const payload = Buffer.from(JSON.stringify({ claims })).toString('base64url');
  return `${header}.${payload}.fakesignature`;
}

describe('TenantAuthMiddleware', () => {
  const TENANT_ID = '64f0c18f7c4d2f0012ab0000';
  const ACTOR_ID = '64f0c18f7c4d2f0012ab1111';
  const BRANCH_ID = '64f0c18f7c4d2f0012ab2222';

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('allows a request with a valid tenant token and sets trustedContext', async () => {
    mockFetchOnce({
      ok: true,
      status: 200,
      json: () =>
        Promise.resolve({
          data: { actorId: ACTOR_ID, tenantId: TENANT_ID, branchId: BRANCH_ID, kind: 'tenant' },
        }),
    });

    const middleware = new TenantAuthMiddleware(buildConfigService());
    const token = buildTenantAccessToken({
      userId: ACTOR_ID,
      tenantId: TENANT_ID,
      roleCode: 'Owner',
    });
    const request = buildRequest(`Bearer ${token}`);
    const next = jest.fn();

    await middleware.use(request, {}, next);

    expect(next).toHaveBeenCalled();
    expect(request.trustedContext).toEqual({
      actorId: ACTOR_ID,
      tenantId: TENANT_ID,
      branchId: BRANCH_ID,
      roleCode: 'Owner',
      permissions: [],
    });
  });

  it('(d) rejects a request with no authorization header at all', async () => {
    const middleware = new TenantAuthMiddleware(buildConfigService());
    const request = buildRequest(undefined);

    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('(d) rejects a request whose token auth-service itself rejects (garbage/expired token)', async () => {
    mockFetchOnce({ ok: false, status: 401 });

    const middleware = new TenantAuthMiddleware(buildConfigService());
    const request = buildRequest('Bearer not-a-real-token');

    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('(d) rejects when auth-service reports the branch as forbidden', async () => {
    mockFetchOnce({ ok: false, status: 403 });

    const middleware = new TenantAuthMiddleware(buildConfigService());
    const request = buildRequest('Bearer some-token');

    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('(e) rejects a request using our own admin JWT from Phase 1 — proves the two auth systems are separate', async () => {
    // Simulates the REAL behavior: auth-service tries to verify this token
    // with ITS OWN AUTH_ACCESS_TOKEN_SECRET, which cannot match a token
    // signed with PLATFORM_ADMIN_ACCESS_TOKEN_SECRET — auth-service itself
    // returns 401 for /v1/auth/context before this middleware even looks at
    // the token's shape.
    mockFetchOnce({ ok: false, status: 401 });

    const jwtService = new JwtService();
    const adminToken = await jwtService.signAsync(
      {
        sub: '64f0c18f7c4d2f0012ab3401',
        email: 'admin@nexoraa.com',
        role: AdminRole.SUPER_ADMIN,
        type: PLATFORM_ADMIN_ACCESS_TOKEN_TYPE,
      },
      {
        secret: 'a'.repeat(40),
        expiresIn: 900,
        issuer: PLATFORM_ADMIN_TOKEN_ISSUER,
        audience: PLATFORM_ADMIN_TOKEN_AUDIENCE,
      },
    );

    const middleware = new TenantAuthMiddleware(buildConfigService());
    const request = buildRequest(`Bearer ${adminToken}`);

    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('fails closed (not open) when auth-service is unreachable', async () => {
    (global as unknown as { fetch: jest.Mock }).fetch = jest
      .fn()
      .mockRejectedValue(new Error('ECONNREFUSED'));

    const middleware = new TenantAuthMiddleware(buildConfigService());
    const request = buildRequest('Bearer some-token');

    await expect(middleware.use(request, {}, jest.fn())).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
