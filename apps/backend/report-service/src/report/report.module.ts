import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from '@nexoraa/database';

import { ReportAuthenticationMiddleware } from './report-auth.middleware';
import { ReportController } from './report.controller';
import { ReportScopeGuard } from './report.guard';
import { MongoReportRepository } from './report.mongo.repository';
import { ReportService } from './report.service';
import { REPORT_REPOSITORY } from './report.types';

@Module({
  imports: [ConfigModule, DatabaseModule],
  controllers: [ReportController],
  providers: [
    ReportAuthenticationMiddleware,
    ReportScopeGuard,
    MongoReportRepository,
    ReportService,
    { provide: REPORT_REPOSITORY, useExisting: MongoReportRepository },
  ],
  exports: [ReportService],
})
export class ReportModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(ReportAuthenticationMiddleware).forRoutes(ReportController);
  }
}
