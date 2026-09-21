import { timingSafeEqual } from 'node:crypto';

import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

interface InternalServiceRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
}

/**
 * Protects the internal enforcement endpoint — this is service-to-service
 * traffic, not admin-to-service, so it deliberately does NOT use
 * PlatformRoleGuard. Mirrors the existing precedent in this codebase
 * (service-service's catalog-provisioning.guard.ts): a shared-secret header
 * checked against an env var, not a tenant/admin JWT.
 *
 * Fails CLOSED (rejects) when the secret is unset or doesn't match — this is
 * an authentication boundary, not the business-logic enforcement decision
 * (which fails OPEN, in EnforcementService). An unauthenticated internal
 * endpoint would be a real vulnerability; a working-but-disabled enforcement
 * feature is the safe default the kill switch already provides.
 */
@Injectable()
export class InternalServiceGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<InternalServiceRequest>();
    const provided = this.header(request, 'x-enforcement-key');
    const expected = this.configService.get<string>('TENANT_ENFORCEMENT_SHARED_SECRET');

    if (!expected || !provided || !this.secureEqual(provided, expected)) {
      throw new UnauthorizedException('A valid internal service key is required');
    }

    return true;
  }

  private header(request: InternalServiceRequest, name: string): string | undefined {
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
