import { SetMetadata } from '@nestjs/common';

import { ModuleKey } from './module-key.enum';

export const REQUIRE_MODULE_KEY = 'requiredModuleKey';

/**
 * Marks a route as gated behind a specific module being enabled for the
 * tenant making the request. Routes with no @RequireModule() are unaffected
 * by ModuleGuard.
 */
export const RequireModule = (moduleKey: ModuleKey): MethodDecorator & ClassDecorator =>
  SetMetadata(REQUIRE_MODULE_KEY, moduleKey);
