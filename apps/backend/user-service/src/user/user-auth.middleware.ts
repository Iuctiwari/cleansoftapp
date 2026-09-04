import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { isOwnerRole } from '@nexoraa/shared';

export interface UserAccessScope {
  readonly actorId: string;
  readonly tenantId: string;
  readonly branchId: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
}

export interface UserAccessRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  userAccessScope?: UserAccessScope;
}

interface AccessTokenEnvelope {
  readonly claims?: {
    readonly userId?: string;
    readonly tenantId?: string;
    readonly roleCode?: string;
    readonly permissions?: readonly string[];
  };
}

@Injectable()
export class UserAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  async use(request: UserAccessRequest, _response: unknown, next: () => void): Promise<void> {
    const authorization = this.header(request, 'authorization');
    const branchId = this.header(request, 'x-branch-id');
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('A valid bearer token is required');
    }
    const baseUrl = this.configService.get<string>(
      'AUTH_SERVICE_BASE_URL',
      'http://localhost:3001/api',
    );
    let response: Response;
    try {
      response = await fetch(`${baseUrl.replace(/\/$/, '')}/v1/auth/context`, {
        headers: { authorization, ...(branchId ? { 'x-branch-id': branchId } : {}) },
      });
    } catch {
      throw new UnauthorizedException('Authentication service is unavailable');
    }
    if (response.status === 403) throw new ForbiddenException('Branch access is forbidden');
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');
    const context = (await response.json()) as {
      data?: { actorId?: string; tenantId?: string; branchId?: string; kind?: string };
    };
    const claims = this.readClaims(authorization.slice('Bearer '.length));
    const isOwner = isOwnerRole(claims.roleCode);
    if (
      context.data?.kind !== 'tenant' ||
      !context.data.actorId ||
      !context.data.tenantId ||
      (!isOwner && !context.data.branchId) ||
      claims.userId !== context.data.actorId ||
      claims.tenantId !== context.data.tenantId ||
      !claims.roleCode
    ) {
      throw new UnauthorizedException('Invalid authenticated context');
    }
    request.userAccessScope = {
      actorId: context.data.actorId,
      tenantId: context.data.tenantId,
      branchId: context.data.branchId ?? '',
      roleCode: claims.roleCode,
      permissions: Object.freeze([...(claims.permissions ?? [])]),
    };
    next();
  }

  private header(request: UserAccessRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private readClaims(token: string): NonNullable<AccessTokenEnvelope['claims']> {
    try {
      const parsed = JSON.parse(
        Buffer.from(token.split('.')[1], 'base64url').toString('utf8'),
      ) as AccessTokenEnvelope;
      if (parsed.claims) return parsed.claims;
    } catch {
      // The token signature is checked by auth-service; malformed local claims are rejected.
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
