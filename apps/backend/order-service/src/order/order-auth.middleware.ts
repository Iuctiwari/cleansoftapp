import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { OrderRequest } from './order.guard';

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

type NextFunction = () => void;

@Injectable()
export class OrderAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  async use(request: OrderRequest, _response: unknown, next: NextFunction): Promise<void> {
    const authorization = this.header(request, 'authorization');
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('A valid bearer token is required');
    }

    const authBaseUrl = this.configService.get<string>(
      'AUTH_SERVICE_BASE_URL',
      'http://localhost:3000/api',
    );
    let response: Response;
    try {
      response = await fetch(`${authBaseUrl.replace(/\/$/, '')}/v1/auth/context`, {
        headers: {
          authorization,
          ...(this.header(request, 'x-branch-id')
            ? { 'x-branch-id': this.header(request, 'x-branch-id')! }
            : {}),
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

    request.trustedContext = {
      actorId: context.actorId,
      authorization,
      branchId: context.branchId,
      permissions: Object.freeze([...(claims.permissions ?? [])]),
      roleCode: claims.roleCode,
      tenantId: context.tenantId,
    };
    next();
  }

  private header(request: OrderRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private readClaims(token: string): NonNullable<AccessTokenEnvelope['claims']> {
    const payload = token.split('.')[1];
    try {
      const envelope = JSON.parse(
        Buffer.from(payload, 'base64url').toString('utf8'),
      ) as AccessTokenEnvelope;
      if (envelope.claims) return envelope.claims;
    } catch {
      // The token was validated by auth-service, but its local representation is unusable.
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
