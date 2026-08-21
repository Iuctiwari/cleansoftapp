import { ForbiddenException, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { NotificationScope } from './notification.types';

interface AuthContextResponse {
  readonly data?: {
    readonly actorId?: string;
    readonly branchId?: string;
    readonly kind?: 'tenant';
    readonly tenantId?: string;
  };
}

interface AccessTokenEnvelope {
  readonly claims?: {
    readonly userId?: string;
    readonly tenantId?: string;
    readonly roleCode?: string;
    readonly permissions?: readonly string[];
  };
}

/**
 * Shared bearer-token verification used by both the HTTP auth middleware and the
 * WebSocket gateway, so the two transports enforce identical tenant/branch/actor rules.
 */
@Injectable()
export class NotificationAuthResolver {
  constructor(private readonly configService: ConfigService) {}

  async resolve(authorization: string, branchId?: string): Promise<NotificationScope> {
    if (!authorization.startsWith('Bearer ')) {
      throw new UnauthorizedException('A valid bearer token is required');
    }

    const authBaseUrl = this.configService.get<string>(
      'AUTH_SERVICE_BASE_URL',
      'http://localhost:3001/api',
    );
    let response: Response;
    try {
      response = await fetch(`${authBaseUrl.replace(/\/$/, '')}/v1/auth/context`, {
        headers: {
          authorization,
          ...(branchId ? { 'x-branch-id': branchId } : {}),
        },
      });
    } catch {
      throw new UnauthorizedException('Authentication service is unavailable');
    }

    if (response.status === 403) throw new ForbiddenException('Branch access is forbidden');
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');

    const context = ((await response.json()) as AuthContextResponse).data;
    const claims = this.readClaims(authorization.slice('Bearer '.length));
    if (
      context?.kind !== 'tenant' ||
      !context.actorId ||
      !context.tenantId ||
      !context.branchId ||
      claims.userId !== context.actorId ||
      claims.tenantId !== context.tenantId ||
      !claims.roleCode
    ) {
      throw new UnauthorizedException('Invalid authenticated context');
    }

    return {
      actorId: context.actorId,
      authorization,
      branchId: context.branchId,
      permissions: Object.freeze([...(claims.permissions ?? [])]),
      roleCode: claims.roleCode,
      tenantId: context.tenantId,
    };
  }

  private readClaims(token: string): NonNullable<AccessTokenEnvelope['claims']> {
    const payload = token.split('.')[1];
    try {
      const envelope = JSON.parse(
        Buffer.from(payload, 'base64url').toString('utf8'),
      ) as AccessTokenEnvelope;
      if (envelope.claims) return envelope.claims;
    } catch {
      // Auth Service already validated the token; reject unusable local claims below.
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
