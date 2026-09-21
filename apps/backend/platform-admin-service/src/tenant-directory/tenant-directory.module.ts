import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { SubscriptionModule } from '../subscription/subscription.module';
import { HttpTenantDirectoryRepository } from './tenant-directory.http.repository';
import { TenantDirectoryController } from './tenant-directory.controller';
import { TenantDirectoryService } from './tenant-directory.service';
import { TENANT_DIRECTORY_REPOSITORY } from './tenant-directory.types';

@Module({
  imports: [
    // See BusinessTypeModule (Phase 1) for why JwtModule must also be
    // imported here: PlatformRoleGuard's own dependencies are resolved via
    // THIS module's injector when attached via @UseGuards().
    JwtModule.register({}),
    // For TENANT_SUBSCRIPTION_REPOSITORY — the overview endpoint enriches
    // tenant-service's directory rows with this service's own subscription
    // data (Company Admin Clients tab).
    SubscriptionModule,
  ],
  controllers: [TenantDirectoryController],
  providers: [
    PlatformRoleGuard,
    TenantDirectoryService,
    HttpTenantDirectoryRepository,
    { provide: TENANT_DIRECTORY_REPOSITORY, useExisting: HttpTenantDirectoryRepository },
  ],
})
export class TenantDirectoryModule {}
