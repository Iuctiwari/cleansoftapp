import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Inject,
  Injectable,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';

import type { ModuleKey } from './module-key.enum';
import {
  TENANT_MODULE_ACCESS_REPOSITORY,
  type TenantModuleAccessRepository,
  type TenantScopedRequest,
} from './module-access.types';
import { REQUIRE_MODULE_KEY } from './require-module.decorator';

/**
 * CRITICAL, NON-NEGOTIABLE: defaults to ALLOW whenever no TenantModuleAccess
 * record exists for the tenant/module pair. Every tenant today has zero such
 * records — a deny-by-default guard here would lock out every existing shop
 * the moment this guard is wired onto a real route (Phase 6).
 *
 * KILL SWITCH (Phase 6, non-negotiable): checks ENFORCE_TENANT_GUARDS before
 * doing anything else — false (the default) means this guard no-ops and
 * passes every request through, identical to not being wired in at all.
 * Flippable via a pure env var, no code change or redeploy required.
 */
@Injectable()
export class ModuleGuard implements CanActivate {
  private readonly logger = new Logger(ModuleGuard.name);

  constructor(
    @Inject(TENANT_MODULE_ACCESS_REPOSITORY)
    private readonly repository: TenantModuleAccessRepository,
    private readonly reflector: Reflector,
    private readonly configService: ConfigService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const enforce = this.configService.get<string>('ENFORCE_TENANT_GUARDS', 'false') === 'true';
    if (!enforce) return true;

    const requiredModule = this.reflector.getAllAndOverride<ModuleKey | undefined>(
      REQUIRE_MODULE_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!requiredModule) return true;

    const request = context.switchToHttp().getRequest<TenantScopedRequest>();
    if (!request.tenantId) {
      this.logger.warn(
        `ModuleGuard applied to a route with no tenantId on the request; failing open for module ${requiredModule}`,
      );
      return true;
    }

    const access = await this.repository.findAccess(request.tenantId, requiredModule);
    if (!access) return true;

    if (!access.isEnabled) {
      throw new ForbiddenException(`The ${requiredModule} module is not enabled for this tenant`);
    }

    return true;
  }
}
