import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { isOwnerRole } from '@nexoraa/shared';

export interface TenantAccessRequest {
  readonly method?: string;
  readonly originalUrl?: string;
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  tenantAccess?: { actorId: string; tenantId: string; roleCode: string };
}

@Injectable()
export class TenantAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly config: ConfigService) {}

  async use(request: TenantAccessRequest, _response: unknown, next: () => void): Promise<void> {
    if (
      (request.method === 'POST' && request.originalUrl?.endsWith('/tenants/register')) ||
      (request.method === 'PATCH' && /\/tenants\/[^/]+$/.test(request.originalUrl ?? ''))
    ) {
      next();
      return;
    }
    const authorization = this.header(request, 'authorization');
    if (!authorization?.startsWith('Bearer '))
      throw new UnauthorizedException('A valid bearer token is required');
    const base = this.config.get<string>('AUTH_SERVICE_BASE_URL', 'http://localhost:3001/api');
    let response: Response;
    try {
      response = await fetch(`${base.replace(/\/$/, '')}/v1/auth/context`, {
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
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');
    const envelope = (await response.json()) as { data?: { actorId?: string; tenantId?: string } };
    const claims = this.claims(authorization.slice('Bearer '.length));
    if (
      !envelope.data?.actorId ||
      !envelope.data.tenantId ||
      claims.userId !== envelope.data.actorId ||
      claims.tenantId !== envelope.data.tenantId ||
      !claims.roleCode
    ) {
      throw new UnauthorizedException('Invalid authenticated context');
    }
    if (!isOwnerRole(claims.roleCode)) throw new ForbiddenException('Owner permission is required');
    request.tenantAccess = {
      actorId: envelope.data.actorId,
      tenantId: envelope.data.tenantId,
      roleCode: claims.roleCode,
    };
    next();
  }

  private header(request: TenantAccessRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private claims(token: string): { userId?: string; tenantId?: string; roleCode?: string } {
    try {
      const parsed = JSON.parse(Buffer.from(token.split('.')[1], 'base64url').toString('utf8')) as {
        claims?: { userId?: string; tenantId?: string; roleCode?: string };
      };
      if (parsed.claims) return parsed.claims;
    } catch {
      // Reject malformed local claims after remote validation.
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
