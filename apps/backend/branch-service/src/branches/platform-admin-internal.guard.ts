import { timingSafeEqual } from 'node:crypto';

import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface InternalRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
}

/**
 * Protects the branch-count endpoint platform-admin-service's Company Admin
 * panel calls (Clients tab — branch/staff counts). Mirrors the existing
 * shared-secret precedent in this codebase (service-service's
 * catalog-provisioning.guard.ts, platform-admin-service's
 * InternalServiceGuard from Phase 6): a header checked against an env var,
 * not a tenant/admin JWT — this is service-to-service traffic.
 *
 * Fails CLOSED (rejects) when the secret is unset or doesn't match — this is
 * an authentication boundary. Unlike Phase 6's enforcement guard, there is no
 * fail-open concern here: this endpoint is read-only display data, and the
 * caller (TenantResourceCountsService in platform-admin-service) already
 * degrades to "unknown" on any failure rather than blocking anything.
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
