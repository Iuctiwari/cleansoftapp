import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { CustomerRequest } from './customer.guard';

interface CustomerAuthenticationRequest extends CustomerRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
}

interface AuthContextEnvelope {
  readonly data?: {
    readonly actorId?: string;
    readonly kind?: 'tenant';
    readonly tenantId?: string;
    readonly branchId?: string;
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
export class CustomerAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  async use(
    request: CustomerAuthenticationRequest,
    _response: unknown,
    next: NextFunction,
  ): Promise<void> {
    const authorization = this.header(request, 'authorization');
    if (!authorization) {
      next();
      return;
    }
    if (!authorization.startsWith('Bearer ')) {
      throw new UnauthorizedException('Invalid authorization header');
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

    const envelope = (await response.json()) as AuthContextEnvelope;
    const context = envelope.data;
    const claims = this.readClaims(authorization.slice('Bearer '.length));
    if (
      !context?.actorId ||
      !context.tenantId ||
      !context.branchId ||
      context.kind !== 'tenant' ||
      claims.userId !== context.actorId ||
      claims.tenantId !== context.tenantId ||
      !claims.roleCode
    ) {
      throw new UnauthorizedException('Invalid authenticated context');
    }
    request.trustedContext = {
      actorId: context.actorId,
      kind: context.kind,
      tenantId: context.tenantId,
      branchId: context.branchId,
      roleCode: claims.roleCode,
      permissions: Object.freeze([...(claims.permissions ?? [])]),
    };
    next();
  }

  private header(request: CustomerAuthenticationRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private readClaims(token: string): NonNullable<AccessTokenEnvelope['claims']> {
    try {
      const envelope = JSON.parse(
        Buffer.from(token.split('.')[1], 'base64url').toString('utf8'),
      ) as AccessTokenEnvelope;
      if (envelope.claims) return envelope.claims;
    } catch {
      // Auth service already validates the signature; reject malformed local claims.
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
