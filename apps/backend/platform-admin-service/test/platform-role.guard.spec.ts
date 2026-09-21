import { createHmac } from 'node:crypto';

import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';

import {
  PlatformRoleGuard,
  type PlatformAdminRequest,
} from '../src/admin-auth/platform-role.guard';
import {
  AdminRole,
  PLATFORM_ADMIN_ACCESS_TOKEN_TYPE,
  PLATFORM_ADMIN_TOKEN_AUDIENCE,
  PLATFORM_ADMIN_TOKEN_ISSUER,
} from '../src/admin-auth/admin-auth.types';

const PLATFORM_ADMIN_ACCESS_SECRET = 'a'.repeat(40);

function buildConfigService(secret: string = PLATFORM_ADMIN_ACCESS_SECRET): ConfigService {
  return {
    getOrThrow: () => secret,
  } as unknown as ConfigService;
}

function buildContext(authorizationHeader?: string): ExecutionContext {
  const request: PlatformAdminRequest = {
    headers: authorizationHeader ? { authorization: authorizationHeader } : {},
  };

  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => (): void => undefined,
    getClass: () => class {},
  } as unknown as ExecutionContext;
}

function base64UrlEncode(value: string): string {
  return Buffer.from(value, 'utf8').toString('base64url');
}

/**
 * Replicates auth-service's own hand-rolled token format
 * (apps/backend/auth-service/src/auth/auth.crypto.ts signToken) to prove a
 * tenant-issued token from that entirely separate system is rejected here.
 */
function signAuthServiceStyleToken(secret: string): string {
  const header = { alg: 'HS256', typ: 'JWT' };
  const payload = {
    issuer: 'nexoraa-auth-service',
    audience: 'nexoraa-tenant-client',
    subject: '64f0c18f7c4d2f0012ab9999',
    tokenKind: 'access',
    issuedAt: Math.floor(Date.now() / 1000),
    expiresAt: Math.floor(Date.now() / 1000) + 900,
    claims: {
      userId: '64f0c18f7c4d2f0012ab9999',
      tenantId: '64f0c18f7c4d2f0012ab0000',
      roleCode: 'Owner',
      kind: 'tenant',
    },
  };
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signature = createHmac('sha256', secret)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64url');

  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

describe('PlatformRoleGuard', () => {
  const jwtService = new JwtService();

  async function signValidAdminToken(): Promise<string> {
    return jwtService.signAsync(
      {
        sub: '64f0c18f7c4d2f0012ab3401',
        email: 'admin@nexoraa.com',
        role: AdminRole.SUPER_ADMIN,
        type: PLATFORM_ADMIN_ACCESS_TOKEN_TYPE,
      },
      {
        secret: PLATFORM_ADMIN_ACCESS_SECRET,
        expiresIn: 900,
        issuer: PLATFORM_ADMIN_TOKEN_ISSUER,
        audience: PLATFORM_ADMIN_TOKEN_AUDIENCE,
      },
    );
  }

  it('(c) allows a request carrying a valid new-format platform admin JWT', async () => {
    const guard = new PlatformRoleGuard(jwtService, buildConfigService(), new Reflector());
    const token = await signValidAdminToken();
    const context = buildContext(`Bearer ${token}`);

    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  it('(d) rejects a request with no authorization header', async () => {
    const guard = new PlatformRoleGuard(jwtService, buildConfigService(), new Reflector());
    const context = buildContext(undefined);

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('(d) rejects a syntactically invalid token', async () => {
    const guard = new PlatformRoleGuard(jwtService, buildConfigService(), new Reflector());
    const context = buildContext('Bearer not-a-real-token');

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('(d) rejects a token signed with the wrong secret', async () => {
    const guard = new PlatformRoleGuard(jwtService, buildConfigService(), new Reflector());
    const tokenSignedWithDifferentSecret = await jwtService.signAsync(
      {
        sub: '64f0c18f7c4d2f0012ab3401',
        email: 'admin@nexoraa.com',
        role: AdminRole.SUPER_ADMIN,
        type: PLATFORM_ADMIN_ACCESS_TOKEN_TYPE,
      },
      {
        secret: 'z'.repeat(40),
        expiresIn: 900,
        issuer: PLATFORM_ADMIN_TOKEN_ISSUER,
        audience: PLATFORM_ADMIN_TOKEN_AUDIENCE,
      },
    );
    const context = buildContext(`Bearer ${tokenSignedWithDifferentSecret}`);

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('(e) rejects a tenant-issued JWT from the existing auth-service system, proving isolation', async () => {
    const guard = new PlatformRoleGuard(jwtService, buildConfigService(), new Reflector());
    // Signed with what would be auth-service's AUTH_ACCESS_TOKEN_SECRET — a
    // value this service never has access to and never uses.
    const authServiceSecret = 'dev_access_secret_completely_unrelated_to_platform_admin';
    const tenantToken = signAuthServiceStyleToken(authServiceSecret);
    const context = buildContext(`Bearer ${tenantToken}`);

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
