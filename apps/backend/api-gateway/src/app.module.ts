import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AuditModule } from './audit/audit.module';
import { PlatformModule } from './platform/platform.module';
import { SchedulerModule } from './scheduler/scheduler.module';

@Module({
  imports: [ConfigModule.forRoot(), PlatformModule, AuditModule, SchedulerModule],
})
export class AppModule {}
