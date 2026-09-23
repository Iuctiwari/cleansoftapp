import { logger } from './logger';
import { pingAll, type PingResult } from './ping';
import type { ResolvedTarget } from './config';

export interface SchedulerStatus {
  readonly intervalMs: number;
  readonly isRunning: boolean;
  readonly lastRunStartedAt: string | null;
  readonly lastRunFinishedAt: string | null;
  readonly lastResults: readonly PingResult[];
}

/**
 * Runs `pingAll` on a fixed interval. If a previous round is still in
 * flight when the next tick fires — e.g. several targets are slow — that
 * tick is skipped rather than starting an overlapping round.
 */
export class KeepAliveScheduler {
  private isRunning = false;
  private lastRunStartedAt: string | null = null;
  private lastRunFinishedAt: string | null = null;
  private lastResults: PingResult[] = [];
  private timer: ReturnType<typeof setInterval> | undefined;

  constructor(
    private readonly targets: readonly ResolvedTarget[],
    private readonly intervalMs: number,
    private readonly requestTimeoutMs: number,
    private readonly concurrency: number,
  ) {}

  start(): void {
    if (this.targets.length === 0) {
      logger.warn('Scheduler', 'No ping targets configured — nothing to keep alive.');
      return;
    }
    logger.log(
      'Scheduler',
      `Starting: ${this.targets.length} target(s), every ${this.intervalMs}ms.`,
    );
    void this.runOnce();
    this.timer = setInterval(() => {
      void this.runOnce();
    }, this.intervalMs);
  }

  stop(): void {
    if (this.timer !== undefined) clearInterval(this.timer);
  }

  getStatus(): SchedulerStatus {
    return {
      intervalMs: this.intervalMs,
      isRunning: this.isRunning,
      lastRunStartedAt: this.lastRunStartedAt,
      lastRunFinishedAt: this.lastRunFinishedAt,
      lastResults: this.lastResults,
    };
  }

  private async runOnce(): Promise<void> {
    if (this.isRunning) {
      logger.warn('Scheduler', 'Previous ping round still in flight — skipping this tick.');
      return;
    }

    this.isRunning = true;
    this.lastRunStartedAt = new Date().toISOString();
    try {
      const results = await pingAll(this.targets, this.requestTimeoutMs, this.concurrency);
      this.lastResults = results;
      for (const result of results) {
        const outcome = result.success ? 'ok' : 'FAILED';
        const detail =
          result.httpStatus !== undefined
            ? `status=${result.httpStatus}`
            : (result.error ?? 'unknown error');
        logger.log(
          'Ping',
          `${result.name} ${outcome} (${detail}, ${result.responseTimeMs}ms) ${result.url}`,
        );
      }
      const failures = results.filter((result) => !result.success).length;
      if (failures > 0) {
        logger.warn('Scheduler', `Round finished: ${failures}/${results.length} target(s) failed.`);
      } else {
        logger.log(
          'Scheduler',
          `Round finished: ${results.length}/${results.length} target(s) ok.`,
        );
      }
    } catch (error) {
      // Defensive only — pingAll does not throw. Never let a round crash the process.
      logger.error('Scheduler', `Unexpected error during ping round: ${(error as Error).message}`);
    } finally {
      this.lastRunFinishedAt = new Date().toISOString();
      this.isRunning = false;
    }
  }
}
