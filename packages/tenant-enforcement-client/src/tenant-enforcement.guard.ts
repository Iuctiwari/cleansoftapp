import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';

import { ModuleKey } from './module-key.enum';
import { REQUIRE_MODULE_KEY } from './require-module.decorator';
import type { TenantEnforcementResponse } from './tenant-enforcement.types';

const REQUEST_TIMEOUT_MS = 3_000;

/**
 * Creates a per-service CanActivate guard that calls platform-admin-service's
 * internal enforcement endpoint. `extractTenantId` is the ONLY thing that
 * varies per service — each existing auth middleware/guard in this repo
 * populates tenantId on a differently-named scope property (orderScope,
 * paymentScope, expenseScope, customerScope, trustedContext, ...); this
 * factory lets each service supply that one line without duplicating
 * anything else (the kill-switch check, the HTTP call, the fail-open
 * semantics, and the ModuleGuard-equivalent check all live here, once).
 *
 * KILL SWITCH: checks ENFORCE_TENANT_GUARDS before doing anything else,
 * including before extracting tenantId or making any network call — when
 * false (the default), this is a true no-op, not just "ignores the result."
 *
 * FAIL OPEN: any network error, timeout, or non-2xx response from
 * platform-admin-service allows the request through. This guard must never
 * become a single point of failure that blocks writes across every tenant
 * if platform-admin-service is slow or unreachable.
 */
export function createTenantEnforcementGuard<TRequest extends object>(
  extractTenantId: (request: TRequest) => string | undefined,
): new (configService: ConfigService, reflector: Reflector) => CanActivate {
  @Injectable()
  class TenantEnforcementGuard implements CanActivate {
    private readonly logger = new Logger(TenantEnforcementGuard.name);

    constructor(
      private readonly configService: ConfigService,
      private readonly reflector: Reflector,
    ) {}

    async canActivate(context: ExecutionContext): Promise<boolean> {
      const enforce = this.configService.get<string>('ENFORCE_TENANT_GUARDS', 'false') === 'true';
      if (!enforce) return true;

      const request = context.switchToHttp().getRequest<TRequest>();
      const tenantId = extractTenantId(request);
      if (!tenantId) return true; // no tenant context on this request — nothing to check

      const requiredModule = this.reflector.getAllAndOverride<ModuleKey | undefined>(
        REQUIRE_MODULE_KEY,
        [context.getHandler(), context.getClass()],
      );

      const response = await this.fetchEnforcement(tenantId);
      if (!response) return true; // fail open — see class doc

      if (!response.writeAllowed) {
        throw new ForbiddenException(
          response.blockedReason ??
            'This tenant is not permitted to perform write actions right now',
        );
      }
      if (requiredModule && response.disabledModuleKeys.includes(requiredModule)) {
        throw new ForbiddenException(`The ${requiredModule} module is not enabled for this tenant`);
      }
      return true;
    }

    private async fetchEnforcement(tenantId: string): Promise<TenantEnforcementResponse | null> {
      const baseUrl = this.configService.get<string>(
        'PLATFORM_ADMIN_SERVICE_BASE_URL',
        'http://localhost:3015/api',
      );
      const sharedSecret = this.configService.get<string>('TENANT_ENFORCEMENT_SHARED_SECRET');

      try {
        const response = await fetch(
          `${baseUrl.replace(/\/$/, '')}/v1/platform-admin/internal/enforcement/${tenantId}`,
          {
            headers: sharedSecret ? { 'x-enforcement-key': sharedSecret } : {},
            signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
          },
        );

        if (!response.ok) {
          this.logger.warn(
            `[tenant-enforcement-failed] reason=http_${response.status} tenantId=${tenantId} failing_open=true`,
          );
          return null;
        }

        return (await response.json()) as TenantEnforcementResponse;
      } catch (error) {
        this.logger.warn(
          `[tenant-enforcement-failed] reason=network_error tenantId=${tenantId} failing_open=true: ${(error as Error).message}`,
        );
        return null;
      }
    }
  }

  return TenantEnforcementGuard;
}
