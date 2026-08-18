import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';

import { CatalogAuthenticationMiddleware } from './catalog-auth.middleware';
import {
  ItemCategoryController,
  ServiceCategoryController,
  ServiceController,
  ServiceMappingController,
} from './catalog.controller';
import { CatalogScopeGuard } from './catalog.guard';
import { CatalogIdPipe } from './catalog-id.pipe';
import { CatalogIndexService } from './catalog-index.service';
import { CatalogProvisioningController } from './catalog-provisioning.controller';
import { CatalogProvisioningGuard } from './catalog-provisioning.guard';
import { CatalogProvisioningService } from './catalog-provisioning.service';
import { HttpCatalogDependencies } from './catalog.integrations';
import { MongoCatalogRepository } from './catalog.mongo.repository';
import {
  CatalogTemplateMongoose,
  CatalogTemplateMongooseSchema,
  ItemCategoryMongoose,
  ItemCategoryMongooseSchema,
  ServiceCategoryMongoose,
  ServiceCategoryMongooseSchema,
  ServiceMappingMongoose,
  ServiceMappingMongooseSchema,
  ServiceMongoose,
  ServiceMongooseSchema,
  ServicePricingMongoose,
  ServicePricingMongooseSchema,
} from './catalog.schema';
import { CatalogService } from './catalog.service';
import { CatalogTemplateSeeder } from './catalog-template.seeder';
import { CATALOG_DEPENDENCIES, CATALOG_REPOSITORY } from './catalog.types';

const tenantCatalogControllers = [
  ItemCategoryController,
  ServiceCategoryController,
  ServiceController,
  ServiceMappingController,
];
const controllers = [...tenantCatalogControllers, CatalogProvisioningController];

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    MongooseModule.forFeature([
      { name: CatalogTemplateMongoose.name, schema: CatalogTemplateMongooseSchema },
      { name: ItemCategoryMongoose.name, schema: ItemCategoryMongooseSchema },
      { name: ServiceCategoryMongoose.name, schema: ServiceCategoryMongooseSchema },
      { name: ServiceMongoose.name, schema: ServiceMongooseSchema },
      { name: ServiceMappingMongoose.name, schema: ServiceMappingMongooseSchema },
      { name: ServicePricingMongoose.name, schema: ServicePricingMongooseSchema },
    ]),
  ],
  controllers,
  providers: [
    CatalogService,
    CatalogAuthenticationMiddleware,
    CatalogScopeGuard,
    CatalogIdPipe,
    CatalogIndexService,
    CatalogProvisioningGuard,
    CatalogProvisioningService,
    CatalogTemplateSeeder,
    MongoCatalogRepository,
    { provide: CATALOG_REPOSITORY, useExisting: MongoCatalogRepository },
    HttpCatalogDependencies,
    { provide: CATALOG_DEPENDENCIES, useExisting: HttpCatalogDependencies },
  ],
  exports: [CatalogTemplateSeeder],
})
export class CatalogModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CatalogAuthenticationMiddleware).forRoutes(...tenantCatalogControllers);
  }
}
