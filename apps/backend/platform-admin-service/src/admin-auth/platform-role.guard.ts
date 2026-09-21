import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Reflector } from '@nestjs/core';

import {
  PLATFORM_ADMIN_ACCESS_TOKEN_TYPE,
  PLATFORM_ADMIN_TOKEN_AUDIENCE,
  PLATFORM_ADMIN_TOKEN_ISSUER,
  type AdminRole,
  type PlatformAdminAccessTokenClaims,
  type PlatformAdminContext,
} from './admin-auth.types';
import { PLATFORM_ROLES_KEY } from './platform-role.decorator';

export interface PlatformAdminRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  platformAdmin?: PlatformAdminContext;
}

/**
 * Validates ONLY tokens issued by this service's own AdminAuthService, signed with
 * PLATFORM_ADMIN_ACCESS_TOKEN_SECRET. This guard, and this token format, is not
 * wired into and does not recognize any token issued by auth-service (tenant or
 * platform-kind) — a token from that system will fail signature verification here
 * because it is signed with a completely different secret.
 */
@Injectable()
export class PlatformRoleGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<PlatformAdminRequest>();
    const authorization = this.header(request, 'authorization');
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('A valid platform admin bearer token is required');
    }

    const token = authorization.slice('Bearer '.length);
    const accessSecret = this.configService.getOrThrow<string>(
      'PLATFORM_ADMIN_ACCESS_TOKEN_SECRET',
    );

    let claims: PlatformAdminAccessTokenClaims;
    try {
      claims = await this.jwtService.verifyAsync<PlatformAdminAccessTokenClaims>(token, {
        secret: accessSecret,
        issuer: PLATFORM_ADMIN_TOKEN_ISSUER,
        audience: PLATFORM_ADMIN_TOKEN_AUDIENCE,
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired platform admin token');
    }

    if (claims.type !== PLATFORM_ADMIN_ACCESS_TOKEN_TYPE) {
      throw new UnauthorizedException('Invalid or expired platform admin token');
    }

    const requiredRoles = this.reflector.getAllAndOverride<AdminRole[] | undefined>(
      PLATFORM_ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (requiredRoles && requiredRoles.length > 0 && !requiredRoles.includes(claims.role)) {
      throw new ForbiddenException('This platform admin role is not permitted for this action');
    }

    request.platformAdmin = { id: claims.sub, email: claims.email, role: claims.role };
    return true;
  }

  private header(request: PlatformAdminRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }
}
