import { randomUUID } from 'node:crypto';
import { Injectable, type NestMiddleware } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { TrustedContextFactory } from './platform.context';
import { PlatformError } from './platform.errors';
import { verifyAccessToken } from './platform.jwt';
import type { RequestWithPlatformContext } from './platform.request';

interface MiddlewareResponse {
  readonly locals?: Record<string, unknown>;
}

type NextFunction = () => void;

/**
 * Populates request.trustedContext from the bearer access token issued by
 * auth-service, reusing the same signing secret and claim shape — this is
 * the same JWT contract, verified in a second location, not a second auth
 * system. Every route in this service requires a valid token; unauthenticated
 * requests are rejected here rather than left to each controller.
 */
@Injectable()
export class TrustedContextMiddleware implements NestMiddleware {
  constructor(
    private readonly configService: ConfigService,
    private readonly trustedContextFactory: TrustedContextFactory,
  ) {}

  use(
    request: RequestWithPlatformContext,
    _response: MiddlewareResponse,
    next: NextFunction,
  ): void {
    const authorization = request.headers.authorization ?? request.headers.Authorization;
    const rawHeader = Array.isArray(authorization) ? authorization[0] : authorization;

    if (!rawHeader || !rawHeader.startsWith('Bearer ')) {
      throw new PlatformError({
        code: 'platform.unauthenticated',
        category: 'unauthenticated',
        messageKey: 'errors.unauthenticated',
      });
    }

    const token = rawHeader.slice('Bearer '.length).trim();
    const secret =
      this.configService.get<string>('AUTH_ACCESS_TOKEN_SECRET') ?? 'dev-access-token-secret';
    const claims = verifyAccessToken(token, secret);

    const requestId = this.resolveHeaderValue(request.headers['x-request-id']) ?? randomUUID();
    const correlationId =
      request.correlationId ??
      this.resolveHeaderValue(request.headers['x-correlation-id']) ??
      requestId;

    if (claims.kind === 'platform') {
      request.trustedContext = this.trustedContextFactory.createPlatformContext({
        actorId: claims.userId,
        actorType: 'user',
        correlationId,
        causationId: requestId,
        requestId,
        sessionId: claims.sessionId,
        roleCode: claims.roleCode,
        permissions: claims.permissions,
        accessVersion: claims.accessVersion,
      });
      next();
      return;
    }

    // A tenant-scoped token must carry a real tenantId. There is no safe
    // fallback here — a fabricated tenant ID would let a malformed or
    // stale token silently resolve into a phantom tenant scope. Reject
    // outright instead, via the same PlatformError/unauthenticated path
    // used for every other authentication failure.
    if (!claims.tenantId || claims.tenantId.trim().length === 0) {
      throw new PlatformError({
        code: 'platform.tenant_context_missing',
        category: 'unauthenticated',
        messageKey: 'errors.platform.tenant_context_missing',
      });
    }

    request.trustedContext = this.trustedContextFactory.createTenantContext({
      actorId: claims.userId,
      actorType: 'user',
      correlationId,
      causationId: requestId,
      requestId,
      tenantId: claims.tenantId,
      branchId: claims.branchId,
      permissions: claims.permissions,
      accessVersion: claims.accessVersion,
      sessionId: claims.sessionId,
      roleCode: claims.roleCode,
    });

    next();
  }

  private resolveHeaderValue(value: string | string[] | undefined): string | undefined {
    return Array.isArray(value) ? value[0] : value;
  }
}
