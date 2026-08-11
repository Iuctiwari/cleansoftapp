import { Module } from '@nestjs/common';

import { PlatformModule } from '../platform/platform.module';
import { AuditController } from './audit.controller';
import { InMemoryAuditRepository } from './audit.repository';
import { AuditService } from './audit.service';
import { AUDIT_REPOSITORY } from './audit.types';

@Module({
  imports: [PlatformModule],
  controllers: [AuditController],
  providers: [
    AuditService,
    InMemoryAuditRepository,
    {
      provide: AUDIT_REPOSITORY,
      useExisting: InMemoryAuditRepository,
    },
  ],
  exports: [AuditService, AUDIT_REPOSITORY],
})
export class AuditModule {}
