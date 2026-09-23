import { performance } from 'node:perf_hooks';

import type { ResolvedTarget } from './config';

export interface PingResult {
  readonly name: string;
  readonly url: string;
  readonly timestamp: string;
  readonly success: boolean;
  readonly httpStatus?: number;
  readonly responseTimeMs: number;
  readonly error?: string;
}

/**
 * Pings a single target. Never throws — a failed request becomes a
 * `success: false` result so one unreachable service can never take down
 * the ping loop or the rest of the round.
 */
export async function pingOne(target: ResolvedTarget, timeoutMs: number): Promise<PingResult> {
  const timestamp = new Date().toISOString();
  const startedAt = performance.now();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);

  try {
    const response = await fetch(target.url, { signal: controller.signal });
    return {
      name: target.name,
      url: target.url,
      timestamp,
      success: response.status < 500,
      httpStatus: response.status,
      responseTimeMs: Math.round(performance.now() - startedAt),
    };
  } catch (error) {
    const isAbort = error instanceof Error && error.name === 'AbortError';
    return {
      name: target.name,
      url: target.url,
      timestamp,
      success: false,
      responseTimeMs: Math.round(performance.now() - startedAt),
      error: isAbort ? `timed out after ${timeoutMs}ms` : (error as Error).message,
    };
  } finally {
    clearTimeout(timeout);
  }
}

/**
 * Pings every target with at most `concurrency` requests in flight at once.
 *
 * This isn't just politeness — Node's default libuv thread pool (used for
 * DNS lookups) is only 4 wide. Firing 14+ requests to 14+ distinct new
 * hostnames at once saturates it, and most requests then sit queued long
 * enough to hit the per-request timeout even though every target is
 * actually healthy (verified: with unlimited concurrency here, 13/14 local
 * targets "timed out" at 15s; the same targets all resolved in under a
 * second once concurrency was bounded). Capping concurrency fixes this
 * without depending on the deployment environment's thread pool size.
 */
export async function pingAll(
  targets: readonly ResolvedTarget[],
  timeoutMs: number,
  concurrency = 4,
): Promise<PingResult[]> {
  const results: PingResult[] = new Array<PingResult>(targets.length);
  let nextIndex = 0;

  async function worker(): Promise<void> {
    while (nextIndex < targets.length) {
      const index = nextIndex;
      nextIndex += 1;
      results[index] = await pingOne(targets[index], timeoutMs);
    }
  }

  const workerCount = Math.min(concurrency, targets.length);
  await Promise.all(Array.from({ length: workerCount }, () => worker()));
  return results;
}
