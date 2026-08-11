import { Inject, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { AuditService } from '../audit/audit.service';
import { PlatformError } from '../platform/platform.errors';
import type { PaginatedResult, TrustedContext } from '../platform/platform.types';
import {
  QUEUE_DISPATCHER,
  SCHEDULER_REPOSITORY,
  type QueueDispatcher,
  type RecoveryResult,
  type RetryOrReplayInput,
  type SchedulerJobInput,
  type SchedulerJobRecord,
  type SchedulerRepository,
  type SchedulerScheduleInput,
  type SchedulerScheduleRecord,
} from './scheduler.types';
import { QueueNameBuilder } from './scheduler.queue';

@Injectable()
export class SchedulerService {
  constructor(
    @Inject(SCHEDULER_REPOSITORY) private readonly schedulerRepository: SchedulerRepository,
    @Inject(QUEUE_DISPATCHER) private readonly queueDispatcher: QueueDispatcher,
    private readonly queueNameBuilder: QueueNameBuilder,
    private readonly auditService: AuditService,
    private readonly configService: ConfigService,
  ) {}

  async scheduleJob(input: SchedulerJobInput): Promise<SchedulerJobRecord> {
    const existing = await this.schedulerRepository.getByIdempotency(
      input.owner,
      input.idempotencyKey,
    );
    if (existing) {
      return existing;
    }

    const queueName = this.queueNameBuilder.build(input.owner, input.tenantId);
    const scheduled = await this.schedulerRepository.scheduleJob(input, queueName);
    await this.queueDispatcher.dispatch(scheduled);
    return scheduled;
  }

  async inspectJob(
    authorization: TrustedContext,
    jobId: string,
  ): Promise<SchedulerJobRecord | null> {
    const job = await this.schedulerRepository.getById(jobId);
    if (job) {
      this.assertJobAuthorization(authorization, job, 'inspect');
    }

    return job;
  }

  async retryOrReplay(input: RetryOrReplayInput): Promise<RecoveryResult> {
    const job = await this.schedulerRepository.getById(input.jobId);
    if (!job) {
      throw new PlatformError({
        code: 'scheduler.job_not_found',
        category: 'not_found',
        messageKey: 'errors.scheduler.job_not_found',
      });
    }

    this.assertJobAuthorization(input.authorization, job, 'replay');

    const replayed: SchedulerJobRecord = {
      ...job,
      status: 'Waiting',
      attempts: 0,
      replayCount: job.replayCount + 1,
      failureReason: undefined,
      deadLetterReason: undefined,
    };

    const updated = await this.schedulerRepository.update(replayed);
    await this.auditService.recordAudit({
      sourceObligation: `scheduler-recovery:${updated.jobId}:${updated.replayCount}`,
      idempotencyKey: `scheduler-recovery:${updated.jobId}:${updated.replayCount}`,
      module: 'scheduler',
      action: 'retry_or_replay',
      classification: 'operational',
      actor: {
        actorId: input.authorization.actorId,
        actorType: input.authorization.actorType,
      },
      target: {
        targetId: updated.jobId,
        targetType: 'scheduler_job',
      },
      context: input.authorization,
      newSummary: {
        fields: {
          reason: input.reason,
          replayCount: updated.replayCount,
          queueName: updated.queueName,
        },
      },
      retentionTags: [{ code: 'ops', label: 'Operations' }],
      contractVersion: { major: 1, minor: 0 },
    });

    await this.queueDispatcher.dispatch(updated);

    return {
      jobId: updated.jobId,
      status: updated.status,
      replayCount: updated.replayCount,
    };
  }

  async registerSchedule(input: SchedulerScheduleInput): Promise<SchedulerScheduleRecord> {
    if (!/^[\d*/,\- ]+$/.test(input.cron)) {
      throw new PlatformError({
        code: 'scheduler.invalid_cron',
        category: 'validation',
        messageKey: 'errors.scheduler.invalid_cron',
      });
    }

    return this.schedulerRepository.registerSchedule(input);
  }

  async listJobs(page: {
    page: number;
    pageSize: number;
  }): Promise<PaginatedResult<SchedulerJobRecord>> {
    return this.schedulerRepository.listJobs(page);
  }

  createJobInputFromContext(
    authorization: TrustedContext,
    request: {
      owner: string;
      version: string;
      payloadReference: string;
      payloadChecksum: string;
      priority: number;
      delayMs: number;
      maxAttempts: number;
      idempotencyKey: string;
      metadata: Record<string, string | number | boolean | null>;
    },
  ): SchedulerJobInput {
    const environment = this.configService.getOrThrow<string>('NODE_ENV');

    return {
      version: request.version,
      owner: request.owner,
      tenantId: 'tenantId' in authorization ? authorization.tenantId : undefined,
      environment,
      scope: {
        tenantId: 'tenantId' in authorization ? authorization.tenantId : undefined,
        branchId: 'branchId' in authorization ? authorization.branchId : undefined,
      },
      requestId: authorization.requestId,
      correlationId: authorization.correlationId,
      idempotencyKey: request.idempotencyKey,
      payloadReference: request.payloadReference,
      payloadChecksum: request.payloadChecksum,
      priority: request.priority,
      delayMs: request.delayMs,
      maxAttempts: request.maxAttempts,
      metadata: request.metadata,
    };
  }

  private assertJobAuthorization(
    authorization: TrustedContext,
    job: SchedulerJobRecord,
    action: 'inspect' | 'replay',
  ): void {
    if (authorization.kind === 'platform') {
      return;
    }

    if (!job.tenantId || authorization.tenantId !== job.tenantId) {
      throw new PlatformError({
        code: `scheduler.${action}_forbidden`,
        category: 'forbidden',
        messageKey: `errors.scheduler.${action}_forbidden`,
      });
    }
  }
}
