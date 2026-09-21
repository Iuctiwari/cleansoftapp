import { SetMetadata } from '@nestjs/common';

import { AdminRole } from './admin-auth.types';

export const PLATFORM_ROLES_KEY = 'platformRoles';

/**
 * Restricts a route to specific AdminRole values. Omit to allow any authenticated
 * platform admin (any valid new-format admin JWT) regardless of role.
 */
export const RequirePlatformRole = (
  ...roles: readonly AdminRole[]
): MethodDecorator & ClassDecorator => SetMetadata(PLATFORM_ROLES_KEY, roles);
