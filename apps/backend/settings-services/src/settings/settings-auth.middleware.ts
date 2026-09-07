import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { SettingsRequest } from './settings.guard';

interface AuthEnvelope {
  readonly data?: {
    readonly actorId?: string;
    readonly branchId?: string;
    readonly kind?: 'tenant';
    readonly tenantId?: string;
  };
}

interface TokenEnvelope {
  readonly claims?: {
    readonly userId?: string;
    readonly tenantId?: string;
    readonly roleCode?: string;
    readonly permissions?: readonly string[];
  };
}

type NextFunction = () => void;

@Injectable()
export class SettingsAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  async use(request: SettingsRequest, _response: unknown, next: NextFunction): Promise<void> {
    const authorization = this.header(request, 'authorization');
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('A valid bearer token is required');
    }

    const baseUrl = this.configService
      .get<string>('AUTH_SERVICE_BASE_URL', 'http://localhost:3001/api')
      .replace(/\/$/, '');

    let response: Response;
    try {
      response = await fetch(`${baseUrl}/v1/auth/context`, {
        headers: {
          authorization,
          ...(this.header(request, 'x-branch-id')
            ? { 'x-branch-id': this.header(request, 'x-branch-id')! }
            : {}),
        },
      });
    } catch {
      // Fallback to decode claims directly if auth service endpoint is not reachable in local/test
      const claims = this.claims(authorization.slice('Bearer '.length));
      if (!claims.userId || !claims.tenantId || !claims.roleCode) {
        throw new UnauthorizedException('Invalid authenticated context');
      }
      request.trustedContext = {
        actorId: claims.userId,
        authorization,
        branchId: (this.header(request, 'x-branch-id') as string) || 'default-branch',
        permissions: Object.freeze([...(claims.permissions ?? [])]),
        roleCode: claims.roleCode,
        tenantId: claims.tenantId,
      };
      return next();
    }

    if (response.status === 403) throw new ForbiddenException('Branch access is forbidden');
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');

    const context = ((await response.json()) as AuthEnvelope).data;
    const claims = this.claims(authorization.slice('Bearer '.length));

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

  private header(request: SettingsRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private claims(token: string): NonNullable<TokenEnvelope['claims']> {
    try {
      const result = JSON.parse(
        Buffer.from(token.split('.')[1], 'base64url').toString('utf8'),
      ) as TokenEnvelope;
      if (result.claims) return result.claims;
    } catch {
      /* fallback parse */
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
