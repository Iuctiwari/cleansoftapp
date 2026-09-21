import { timingSafeEqual } from 'node:crypto';

import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface InternalRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
}

/**
 * Protects the customer-count endpoint platform-admin-service's Company
 * Admin panel calls (tenant detail screen). Same shared-secret pattern as
 * the other services' PlatformAdminInternalGuard — see order-service's
 * copy for the full rationale.
 */
@Injectable()
export class PlatformAdminInternalGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<InternalRequest>();
    const provided = this.header(request, 'x-platform-admin-key');
    const expected = this.configService.get<string>('PLATFORM_ADMIN_INTERNAL_KEY');

    if (!expected || !provided || !this.secureEqual(provided, expected)) {
      throw new UnauthorizedException('A valid internal service key is required');
    }

    return true;
  }

  private header(request: InternalRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private secureEqual(a: string, b: string): boolean {
    const bufferA = Buffer.from(a, 'utf8');
    const bufferB = Buffer.from(b, 'utf8');
    if (bufferA.length !== bufferB.length) return false;
    return timingSafeEqual(bufferA, bufferB);
  }
}
