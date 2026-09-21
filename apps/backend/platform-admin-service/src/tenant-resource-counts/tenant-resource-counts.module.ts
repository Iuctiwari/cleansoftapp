import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { TenantResourceCountsController } from './tenant-resource-counts.controller';
import { TenantResourceCountsService } from './tenant-resource-counts.service';

@Module({
  // See BusinessTypeModule for why JwtModule must also be imported here:
  // PlatformRoleGuard's own dependencies are resolved via THIS module's
  // injector when attached via @UseGuards(), not AdminAuthModule's.
  imports: [JwtModule.register({})],
  controllers: [TenantResourceCountsController],
  providers: [PlatformRoleGuard, TenantResourceCountsService],
})
export class TenantResourceCountsModule {}
