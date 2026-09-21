import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { TENANT_MODULE_ACCESS_REPOSITORY } from './module-access.types';
import { ModuleGuard } from './module.guard';
import { TenantModuleAccessController } from './tenant-module-access.controller';
import { MongoTenantModuleAccessRepository } from './tenant-module-access.mongo.repository';
import {
  TenantModuleAccessMongoose,
  TenantModuleAccessMongooseSchema,
} from './tenant-module-access.mongoose.schema';
import { TenantModuleAccessService } from './tenant-module-access.service';

/**
 * ModuleGuard itself is still not wired onto any route (Phase 6). The
 * controller added in Phase 5 is a separate thing: an admin-facing read/write
 * surface over TenantModuleAccess for module_matrix_screen.dart, guarded by
 * PlatformRoleGuard — unrelated to when/whether ModuleGuard starts enforcing
 * access on tenant-facing routes.
 */
@Module({
  imports: [
    // See BusinessTypeModule (Phase 1) for why JwtModule must also be
    // imported here: PlatformRoleGuard's own dependencies are resolved via
    // THIS module's injector when attached via @UseGuards().
    JwtModule.register({}),
    MongooseModule.forFeature([
      { name: TenantModuleAccessMongoose.name, schema: TenantModuleAccessMongooseSchema },
    ]),
  ],
  controllers: [TenantModuleAccessController],
  providers: [
    PlatformRoleGuard,
    ModuleGuard,
    TenantModuleAccessService,
    MongoTenantModuleAccessRepository,
    { provide: TENANT_MODULE_ACCESS_REPOSITORY, useExisting: MongoTenantModuleAccessRepository },
  ],
  exports: [ModuleGuard, TENANT_MODULE_ACCESS_REPOSITORY],
})
export class ModuleAccessModule {}
