import type { ModuleKey } from './module-key.enum';

/**
 * The single contract between platform-admin-service's internal enforcement
 * endpoint (provider) and every consuming service's guard (client) — imported
 * by BOTH sides so the shape can never silently drift between them.
 */
export interface TenantEnforcementResponse {
  readonly writeAllowed: boolean;
  readonly blockedReason?: string;
  readonly disabledModuleKeys: readonly ModuleKey[];
}
