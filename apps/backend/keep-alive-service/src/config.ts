/**
 * Static catalogue of every service this worker knows how to ping, plus the
 * env var that carries its deployed base URL and the health path that
 * service actually exposes (these differ per service — verified against
 * each one directly rather than assumed).
 *
 * The env var names intentionally match the `RENDER_*_API_BASE_URL` keys
 * already used in apps/mobile-app/.env, so the same values can be copied in.
 * A target is skipped (not pinged) if its env var is unset or empty — this
 * keeps the list forgiving as new services get deployed over time.
 */
export interface ServiceDefinition {
  readonly name: string;
  readonly envVar: string;
  readonly healthPath: string;
}

export const SERVICE_DEFINITIONS: readonly ServiceDefinition[] = [
  { name: 'auth-service', envVar: 'RENDER_AUTH_API_BASE_URL', healthPath: '/api/v1/health/live' },
  { name: 'branch-service', envVar: 'RENDER_BRANCH_API_BASE_URL', healthPath: '/v1/health' },
  { name: 'customer-service', envVar: 'RENDER_CUSTOMER_API_BASE_URL', healthPath: '/health' },
  {
    name: 'notification-service',
    envVar: 'RENDER_NOTIFICATION_API_BASE_URL',
    healthPath: '/api/v1/health',
  },
  { name: 'tenant-service', envVar: 'RENDER_TENANT_API_BASE_URL', healthPath: '/api/v1/health' },
  { name: 'order-service', envVar: 'RENDER_ORDER_API_BASE_URL', healthPath: '/api/v1/health' },
  { name: 'report-service', envVar: 'RENDER_REPORT_API_BASE_URL', healthPath: '/api/v1/health' },
  { name: 'expense-service', envVar: 'RENDER_EXPENSE_API_BASE_URL', healthPath: '/health' },
  { name: 'payment-service', envVar: 'RENDER_PAYMENT_API_BASE_URL', healthPath: '/api/v1/health' },
  { name: 'service-service', envVar: 'RENDER_SERVICE_API_BASE_URL', healthPath: '/api/v1/health' },
  { name: 'user-service', envVar: 'RENDER_USER_API_BASE_URL', healthPath: '/api/v1/health' },
  { name: 'search-service', envVar: 'RENDER_SEARCH_API_BASE_URL', healthPath: '/health' },
  {
    name: 'settings-services',
    envVar: 'RENDER_SETTINGS_API_BASE_URL',
    healthPath: '/api/v1/health',
  },
  {
    name: 'platform-admin-service',
    envVar: 'RENDER_PLATFORM_ADMIN_API_BASE_URL',
    healthPath: '/api/v1/health',
  },
  // Not used by the mobile app, so no RENDER_*_API_BASE_URL exists for these
  // yet. Set these two env vars once their Render URLs are known and they'll
  // start being pinged automatically — no code change needed.
  { name: 'audit-service', envVar: 'RENDER_AUDIT_API_BASE_URL', healthPath: '/health' },
  { name: 'scheduler-service', envVar: 'RENDER_SCHEDULER_API_BASE_URL', healthPath: '/health' },
];

export interface ResolvedTarget {
  readonly name: string;
  readonly url: string;
}

/**
 * Some RENDER_*_API_BASE_URL values already end in `/api` (auth,
 * platform-admin) and some don't (everything else) — see
 * apps/mobile-app/.env. Every `healthPath` below is written as the full
 * path from the host root, so any `/api` (or `/api/v1`, `/v1`) suffix on
 * the configured base must be stripped first, or it doubles up.
 */
function stripKnownSuffixes(value: string): string {
  let trimmed = value.endsWith('/') ? value.slice(0, -1) : value;
  for (const suffix of ['/api/v1', '/v1', '/api']) {
    if (trimmed.endsWith(suffix)) {
      trimmed = trimmed.slice(0, -suffix.length);
      break;
    }
  }
  return trimmed;
}

/** Resolves every configured target whose base-URL env var is actually set. */
export function resolveTargets(env: NodeJS.ProcessEnv): ResolvedTarget[] {
  const targets: ResolvedTarget[] = [];
  for (const definition of SERVICE_DEFINITIONS) {
    const base = env[definition.envVar]?.trim();
    if (base === undefined || base.length === 0) continue;
    targets.push({
      name: definition.name,
      url: `${stripKnownSuffixes(base)}${definition.healthPath}`,
    });
  }
  return targets;
}

export interface AppConfig {
  readonly port: number;
  readonly host: string;
  readonly intervalMs: number;
  readonly requestTimeoutMs: number;
  readonly concurrency: number;
  readonly selfUrl: string | undefined;
  readonly targets: ResolvedTarget[];
}

const DEFAULT_INTERVAL_MS = 120_000;
const DEFAULT_TIMEOUT_MS = 15_000;
const DEFAULT_PORT = 10000;
// Kept at Node's default libuv thread-pool size (4) so DNS lookups for this
// many simultaneous new hosts never queue long enough to hit the request
// timeout. Safe to raise if UV_THREADPOOL_SIZE is also raised to match.
const DEFAULT_CONCURRENCY = 4;

function parsePositiveInt(value: string | undefined, fallback: number): number {
  if (value === undefined || value.trim().length === 0) return fallback;
  const parsed = Number.parseInt(value, 10);
  return Number.isFinite(parsed) && parsed > 0 ? parsed : fallback;
}

export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const selfUrl = env.RENDER_EXTERNAL_URL?.trim();
  return {
    port: parsePositiveInt(env.PORT, DEFAULT_PORT),
    host: '0.0.0.0',
    intervalMs: parsePositiveInt(env.KEEP_ALIVE_INTERVAL_MS, DEFAULT_INTERVAL_MS),
    requestTimeoutMs: parsePositiveInt(env.KEEP_ALIVE_REQUEST_TIMEOUT_MS, DEFAULT_TIMEOUT_MS),
    concurrency: parsePositiveInt(env.KEEP_ALIVE_CONCURRENCY, DEFAULT_CONCURRENCY),
    selfUrl: selfUrl !== undefined && selfUrl.length > 0 ? selfUrl : undefined,
    targets: resolveTargets(env),
  };
}
