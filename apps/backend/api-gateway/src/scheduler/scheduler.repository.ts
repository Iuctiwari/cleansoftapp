import { randomUUID } from 'node:crypto';

import { Injectable } from '@nestjs/common';

import type { PaginatedResult } from '../platform/platform.types';
import type {
  SchedulerJobInput,
  SchedulerJobRecord,
  SchedulerRepository,
  SchedulerScheduleInput,
  SchedulerScheduleRecord,
} from './scheduler.types';

@Injectable()
export class InMemorySchedulerRepository implements SchedulerRepository {
  private readonly jobs = new Map<string, SchedulerJobRecord>();
  private readonly jobsByOwnerAndIdempotency = new Map<string, SchedulerJobRecord>();
  private readonly schedules = new Map<string, SchedulerScheduleRecord>();

  scheduleJob(input: SchedulerJobInput, queueName: string): Promise<SchedulerJobRecord> {
    const timestamp = new Date().toISOString();
    const job: SchedulerJobRecord = {
      ...input,
      jobId: randomUUID(),
      queueName,
      status: input.delayMs > 0 ? 'Delayed' : 'Pending',
      attempts: 0,
      scheduledAtUtc: timestamp,
      createdAtUtc: timestamp,
      updatedAtUtc: timestamp,
      replayCount: 0,
    };

    this.jobs.set(job.jobId, job);
    this.jobsByOwnerAndIdempotency.set(`${job.owner}:${job.idempotencyKey}`, job);
    return Promise.resolve(job);
  }

  getById(jobId: string): Promise<SchedulerJobRecord | null> {
    return Promise.resolve(this.jobs.get(jobId) ?? null);
  }

  getByIdempotency(owner: string, idempotencyKey: string): Promise<SchedulerJobRecord | null> {
    return Promise.resolve(
      this.jobsByOwnerAndIdempotency.get(`${owner}:${idempotencyKey}`) ?? null,
    );
  }

  update(job: SchedulerJobRecord): Promise<SchedulerJobRecord> {
    const updated = { ...job, updatedAtUtc: new Date().toISOString() };
    this.jobs.set(updated.jobId, updated);
    this.jobsByOwnerAndIdempotency.set(`${updated.owner}:${updated.idempotencyKey}`, updated);
    return Promise.resolve(updated);
  }

  registerSchedule(input: SchedulerScheduleInput): Promise<SchedulerScheduleRecord> {
    const schedule: SchedulerScheduleRecord = {
      ...input,
      scheduleId: randomUUID(),
      createdAtUtc: new Date().toISOString(),
    };

    this.schedules.set(schedule.scheduleId, schedule);
    return Promise.resolve(schedule);
  }

  listJobs(page: { page: number; pageSize: number }): Promise<PaginatedResult<SchedulerJobRecord>> {
    const ordered = [...this.jobs.values()].sort((left, right) =>
      right.createdAtUtc.localeCompare(left.createdAtUtc),
    );
    const start = (page.page - 1) * page.pageSize;
    return Promise.resolve({
      items: ordered.slice(start, start + page.pageSize),
      page: page.page,
      pageSize: page.pageSize,
      total: ordered.length,
    });
  }
}
