import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';

import { PlatformRoleGuard } from '../admin-auth/platform-role.guard';
import { ThemeHistoryMongoose, ThemeHistoryMongooseSchema } from './theme-history.mongoose.schema';
import { MongoThemeHistoryRepository } from './theme-history.mongo.repository';
import { TenantThemeMongoose, TenantThemeMongooseSchema } from './tenant-theme.mongoose.schema';
import { MongoTenantThemeRepository } from './tenant-theme.mongo.repository';
import { ThemeController } from './theme.controller';
import { ThemeService } from './theme.service';
import { TENANT_THEME_REPOSITORY, THEME_HISTORY_REPOSITORY } from './theme.types';

@Module({
  imports: [
    // See BusinessTypeModule (Phase 1) for why JwtModule must also be
    // imported here: PlatformRoleGuard's own dependencies are resolved via
    // THIS module's injector when attached via @UseGuards().
    JwtModule.register({}),
    MongooseModule.forFeature([
      { name: TenantThemeMongoose.name, schema: TenantThemeMongooseSchema },
      { name: ThemeHistoryMongoose.name, schema: ThemeHistoryMongooseSchema },
    ]),
  ],
  controllers: [ThemeController],
  providers: [
    PlatformRoleGuard,
    ThemeService,
    MongoTenantThemeRepository,
    MongoThemeHistoryRepository,
    { provide: TENANT_THEME_REPOSITORY, useExisting: MongoTenantThemeRepository },
    { provide: THEME_HISTORY_REPOSITORY, useExisting: MongoThemeHistoryRepository },
  ],
  exports: [ThemeService],
})
export class ThemeModule {}
