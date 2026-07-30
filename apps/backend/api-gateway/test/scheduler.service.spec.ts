import { ConfigService } from '@nestjs/config';

import { InMemoryAuditRepository } from '../src/audit/audit.repository';
import { AuditService } from '../src/audit/audit.service';
import { TrustedContextFactory } from '../src/platform/platform.context';
import { InMemoryQueueDispatcher, QueueNameBuilder } from '../src/scheduler/scheduler.queue';
import { InMemorySchedulerRepository } from '../src/scheduler/scheduler.repository';
import { SchedulerService } from '../src/scheduler/scheduler.service';

describe('SchedulerService', () => {
  const trustedContextFactory = new TrustedContextFactory();

  it('returns the existing job for duplicate owner/idempotency pairs', async () => {
    const configService = new ConfigService({
      NODE_ENV: 'test',
    });
    const auditService = new AuditService(new InMemoryAuditRepository());
    const service = new SchedulerService(
      new InMemorySchedulerRepository(),
      new InMemoryQueueDispatcher(),
      new QueueNameBuilder(configService),
      auditService,
      configService,
    );
    const context = trustedContextFactory.createTenantContext({
      actorId: 'user-1',
      actorType: 'user',
      correlationId: 'corr-1',
      causationId: 'cause-1',
      requestId: 'req-1',
      tenantId: 'tenant-1',
      permissions: ['jobs:write'],
      accessVersion: 3,
    });

    const input = service.createJobInputFromContext(context, {
      owner: 'reports',
      version: '1.0.0',
      payloadReference: 'report:1',
      payloadChecksum: 'checksum',
      priority: 1,
      delayMs: 0,
      maxAttempts: 3,
      idempotencyKey: 'reports:1',
      metadata: {},
    });

    const first = await service.scheduleJob(input);
    const second = await service.scheduleJob(input);

    expect(first.jobId).toBe(second.jobId);
    expect(first.queueName).toBe('test:tenant-1:reports');
  });
});
