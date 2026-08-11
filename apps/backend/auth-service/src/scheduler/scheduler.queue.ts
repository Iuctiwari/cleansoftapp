import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { PlatformError } from '../platform/platform.errors';
import type { QueueDispatchResult, QueueDispatcher, SchedulerJobRecord } from './scheduler.types';

@Injectable()
export class QueueNameBuilder {
  constructor(private readonly configService: ConfigService) {}

  build(owner: string, tenantId?: string): string {
    const environment = this.configService.getOrThrow<string>('NODE_ENV');
    const resolvedTenantId = tenantId ?? 'platform';
    return `${environment}:${resolvedTenantId}:${owner}`;
  }
}

@Injectable()
export class InMemoryQueueDispatcher implements QueueDispatcher {
  dispatch(job: SchedulerJobRecord): Promise<QueueDispatchResult> {
    if (job.payloadReference.trim().length === 0) {
      throw new PlatformError({
        code: 'scheduler.invalid_payload_reference',
        category: 'validation',
        messageKey: 'errors.scheduler.invalid_payload_reference',
      });
    }

    return Promise.resolve({
      queueName: job.queueName,
      jobId: job.jobId,
    });
  }
}
