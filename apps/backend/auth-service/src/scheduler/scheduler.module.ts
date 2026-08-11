import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuditModule } from '../audit/audit.module';
import { PlatformModule } from '../platform/platform.module';
import { SchedulerController } from './scheduler.controller';
import { InMemoryQueueDispatcher, QueueNameBuilder } from './scheduler.queue';
import { InMemorySchedulerRepository } from './scheduler.repository';
import { SchedulerService } from './scheduler.service';
import { QUEUE_DISPATCHER, SCHEDULER_REPOSITORY } from './scheduler.types';

@Module({
  imports: [ConfigModule, AuditModule, PlatformModule],
  controllers: [SchedulerController],
  providers: [
    SchedulerService,
    QueueNameBuilder,
    InMemorySchedulerRepository,
    InMemoryQueueDispatcher,
    {
      provide: SCHEDULER_REPOSITORY,
      useExisting: InMemorySchedulerRepository,
    },
    {
      provide: QUEUE_DISPATCHER,
      useExisting: InMemoryQueueDispatcher,
    },
  ],
})
export class SchedulerModule {}
