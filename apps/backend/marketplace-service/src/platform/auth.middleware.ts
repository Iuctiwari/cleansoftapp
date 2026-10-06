import {
  ForbiddenException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { MarketplaceRequest } from './marketplace.types';

type NextFunction = () => void;

function header(request: MarketplaceRequest, name: string): string | undefined {
  const value = request.headers[name];
  return Array.isArray(value) ? value[0] : value;
}

function bearer(request: MarketplaceRequest): string {
  const authorization = header(request, 'authorization');
  if (!authorization?.startsWith('Bearer ')) {
    throw new UnauthorizedException('A valid bearer token is required');
  }
  return authorization;
}

async function callAuthService(
  configService: ConfigService,
  path: string,
  headers: Record<string, string>,
): Promise<Response> {
  const authBaseUrl = configService.get<string>(
    'AUTH_SERVICE_BASE_URL',
    'http://localhost:3001/api',
  );
  try {
    return await fetch(`${authBaseUrl.replace(/\/$/, '')}${path}`, {
      headers,
      signal: AbortSignal.timeout(5_000),
    });
  } catch {
    throw new ServiceUnavailableException('Authentication service is unavailable');
  }
}

/** Customer routes: the token must belong to a verified, active consumer account. */
@Injectable()
export class ConsumerAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  async use(request: MarketplaceRequest, _response: unknown, next: NextFunction): Promise<void> {
    const response = await callAuthService(this.configService, '/v1/auth/consumer/context', {
      authorization: bearer(request),
    });
    if (response.status === 403) {
      throw new ForbiddenException('A customer account is required');
    }
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');

    const envelope = (await response.json()) as {
      readonly data?: {
        readonly actorId?: string;
        readonly kind?: string;
        readonly displayName?: string;
        readonly email?: string;
        readonly mobileNumber?: string;
      };
    };
    const profile = envelope.data;
    if (profile?.kind !== 'consumer' || !profile.actorId) {
      throw new UnauthorizedException('Invalid authenticated context');
    }

    request.consumer = {
      consumerId: profile.actorId,
      displayName: profile.displayName ?? '',
      email: profile.email ?? '',
      mobileNumber: profile.mobileNumber ?? '',
    };
    next();
  }
}

/**
 * Shop routes: same contract as the other tenant services — auth-service
 * validates the session and that the user is assigned to the requested branch
 * (x-branch-id), and the role/permissions are read from the verified token.
 */
@Injectable()
export class ShopAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  async use(request: MarketplaceRequest, _response: unknown, next: NextFunction): Promise<void> {
    const authorization = bearer(request);
    const branchId = header(request, 'x-branch-id');
    const response = await callAuthService(this.configService, '/v1/auth/context', {
      authorization,
      ...(branchId ? { 'x-branch-id': branchId } : {}),
    });
    if (response.status === 403) throw new ForbiddenException('Branch access is forbidden');
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');

    const envelope = (await response.json()) as {
      readonly data?: {
        readonly actorId?: string;
        readonly kind?: string;
        readonly tenantId?: string;
        readonly branchId?: string;
      };
    };
    const context = envelope.data;
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

    request.shop = {
      actorId: context.actorId,
      tenantId: context.tenantId,
      branchId: context.branchId,
      roleCode: claims.roleCode,
      permissions: Object.freeze([...(claims.permissions ?? [])]),
      authorization,
    };
    next();
  }

  private readClaims(token: string): {
    readonly userId?: string;
    readonly tenantId?: string;
    readonly roleCode?: string;
    readonly permissions?: readonly string[];
  } {
    try {
      const envelope = JSON.parse(
        Buffer.from(token.split('.')[1] ?? '', 'base64url').toString('utf8'),
      ) as { readonly claims?: Record<string, never> };
      if (envelope.claims) return envelope.claims;
    } catch {
      // auth-service already validated the signature; a malformed local copy is rejected below.
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
