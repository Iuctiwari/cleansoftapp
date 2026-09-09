import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';

import { SettingsAuthenticationMiddleware } from './settings-auth.middleware';
import { SettingsIdPipe } from './settings-id.pipe';
import { SettingsProvisioningService } from './settings-provisioning.service';
import { SettingsController } from './settings.controller';
import { SettingsScopeGuard } from './settings.guard';
import { MongoSettingsRepository } from './settings.mongo.repository';
import {
  SettingsItemCategoryMongoose,
  SettingsItemCategoryMongooseSchema,
  SettingsServiceCategoryMongoose,
  SettingsServiceCategoryMongooseSchema,
  SettingsServiceMappingMongoose,
  SettingsServiceMappingMongooseSchema,
  SettingsServiceMongoose,
  SettingsServiceMongooseSchema,
  SettingsServicePricingMongoose,
  SettingsServicePricingMongooseSchema,
} from './settings.schema';
import { SettingsService } from './settings.service';
import { SETTINGS_REPOSITORY } from './settings.types';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    MongooseModule.forFeature([
      { name: SettingsServiceCategoryMongoose.name, schema: SettingsServiceCategoryMongooseSchema },
      { name: SettingsItemCategoryMongoose.name, schema: SettingsItemCategoryMongooseSchema },
      { name: SettingsServiceMongoose.name, schema: SettingsServiceMongooseSchema },
      { name: SettingsServiceMappingMongoose.name, schema: SettingsServiceMappingMongooseSchema },
      { name: SettingsServicePricingMongoose.name, schema: SettingsServicePricingMongooseSchema },
    ]),
  ],
  controllers: [SettingsController],
  providers: [
    SettingsService,
    SettingsProvisioningService,
    SettingsAuthenticationMiddleware,
    SettingsScopeGuard,
    SettingsIdPipe,
    MongoSettingsRepository,
    { provide: SETTINGS_REPOSITORY, useExisting: MongoSettingsRepository },
  ],
  exports: [SettingsService, SettingsProvisioningService],
})
export class SettingsModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(SettingsAuthenticationMiddleware).forRoutes(SettingsController);
  }
}
