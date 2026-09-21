import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { ModuleAccessModule } from '../module-access/module-access.module';
import { ThemeModule } from '../theme/theme.module';
import { TenantAuthMiddleware } from './tenant-auth.middleware';
import { TenantConfigController } from './tenant-config.controller';
import { TenantConfigService } from './tenant-config.service';

@Module({
  imports: [ConfigModule, ThemeModule, ModuleAccessModule],
  controllers: [TenantConfigController],
  providers: [TenantConfigService, TenantAuthMiddleware],
})
export class TenantConfigModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(TenantAuthMiddleware).forRoutes(TenantConfigController);
  }
}
