import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuditModule } from './audit/audit.module';
import { AuthModule } from './auth/auth.module';
import { validateAuthEnvironment } from './auth/auth.config';
import { PlatformModule } from './platform/platform.module';
import { SchedulerModule } from './scheduler/scheduler.module';
import { StaffProvisioningController } from './platform/staff-provisioning.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      expandVariables: true,
      isGlobal: true,
      envFilePath: ['.env', '../../../.env'],
      validate: validateAuthEnvironment,
    }),
    PlatformModule,
    AuditModule,
    AuthModule,
    SchedulerModule,
  ],
  controllers: [StaffProvisioningController],
  providers: [],
})
export class AppModule {}
