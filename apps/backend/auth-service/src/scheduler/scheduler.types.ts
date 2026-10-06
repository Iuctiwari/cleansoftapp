import type { PaginatedResult, StaffTrustedContext } from '../platform/platform.types';

export type SchedulerJobStatus =
  | 'Pending'
  | 'Waiting'
  | 'Delayed'
  | 'Active'
  | 'Completed'
  | 'Failed'
  | 'RetryScheduled'
  | 'DeadLettered'
  | 'Cancelled'
  | 'Expired';

export type ScheduleType = 'immediate' | 'delayed' | 'one_time' | 'recurring' | 'cron';

export interface SchedulerJobScope {
  readonly tenantId?: string;
  readonly branchId?: string;
}

export interface SchedulerJobInput {
  readonly version: string;
  readonly owner: string;
  readonly tenantId?: string;
  readonly environment: string;
  readonly scope: SchedulerJobScope;
  readonly requestId: string;
  readonly correlationId: string;
  readonly idempotencyKey: string;
  readonly payloadReference: string;
  readonly payloadChecksum: string;
  readonly priority: number;
  readonly delayMs: number;
  readonly maxAttempts: number;
  readonly metadata: Record<string, string | number | boolean | null>;
}

export interface SchedulerJobRecord extends SchedulerJobInput {
  readonly jobId: string;
  readonly queueName: string;
  readonly status: SchedulerJobStatus;
  readonly attempts: number;
  readonly scheduledAtUtc: string;
  readonly createdAtUtc: string;
  readonly updatedAtUtc: string;
  readonly failureReason?: string;
  readonly deadLetterReason?: string;
  readonly replayCount: number;
}

export interface SchedulerScheduleInput {
  readonly owner: string;
  readonly tenantId?: string;
  readonly environment: string;
  readonly cron: string;
  readonly timezone: string;
  readonly payloadReference: string;
  readonly payloadChecksum: string;
}

export interface SchedulerScheduleRecord extends SchedulerScheduleInput {
  readonly scheduleId: string;
  readonly createdAtUtc: string;
}

export interface RetryOrReplayInput {
  readonly authorization: StaffTrustedContext;
  readonly jobId: string;
  readonly reason: string;
}

export interface RecoveryResult {
  readonly jobId: string;
  readonly status: SchedulerJobStatus;
  readonly replayCount: number;
}

export interface SchedulerRepository {
  scheduleJob(input: SchedulerJobInput, queueName: string): Promise<SchedulerJobRecord>;
  getById(jobId: string): Promise<SchedulerJobRecord | null>;
  getByIdempotency(owner: string, idempotencyKey: string): Promise<SchedulerJobRecord | null>;
  update(job: SchedulerJobRecord): Promise<SchedulerJobRecord>;
  registerSchedule(input: SchedulerScheduleInput): Promise<SchedulerScheduleRecord>;
  listJobs(page: { page: number; pageSize: number }): Promise<PaginatedResult<SchedulerJobRecord>>;
}

export interface QueueDispatchResult {
  readonly queueName: string;
  readonly jobId: string;
}

export interface QueueDispatcher {
  dispatch(job: SchedulerJobRecord): Promise<QueueDispatchResult>;
}

export const SCHEDULER_REPOSITORY = Symbol('SCHEDULER_REPOSITORY');
export const QUEUE_DISPATCHER = Symbol('QUEUE_DISPATCHER');
