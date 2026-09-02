import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';

import {
  BranchMongoose,
  BranchMongooseSchema,
  TenantMongoose,
  TenantMongooseSchema,
  TenantOwnerMongoose,
  TenantOwnerMongooseSchema,
  TenantServiceMongoose,
  TenantServiceMongooseSchema,
} from './tenant.mongoose.schema';
import { TenantController } from './tenant.controller';
import { HttpTenantCatalogProvisioner } from './catalog-provisioning.client';
import { MongoTenantRepository } from './tenant.mongo.repository';
import { InMemoryTenantRepository } from './tenant.repository';
import { TenantService } from './tenant.service';
import { TENANT_REPOSITORY } from './tenant.types';
import { TENANT_CATALOG_PROVISIONER } from './tenant.types';
import { TenantAuthenticationMiddleware } from './tenant-auth.middleware';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: TenantMongoose.name, schema: TenantMongooseSchema },
      { name: TenantOwnerMongoose.name, schema: TenantOwnerMongooseSchema },
      { name: BranchMongoose.name, schema: BranchMongooseSchema },
      { name: TenantServiceMongoose.name, schema: TenantServiceMongooseSchema },
    ]),
  ],
  controllers: [TenantController],
  providers: [
    TenantService,
    HttpTenantCatalogProvisioner,
    // MongoDB-backed repository — active by default.
    MongoTenantRepository,
    {
      provide: TENANT_REPOSITORY,
      useExisting: MongoTenantRepository,
    },
    {
      provide: TENANT_CATALOG_PROVISIONER,
      useExisting: HttpTenantCatalogProvisioner,
    },
    // In-memory repository kept available for unit tests.
    InMemoryTenantRepository,
    TenantAuthenticationMiddleware,
  ],
  exports: [TenantService],
})
export class TenantModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(TenantAuthenticationMiddleware).forRoutes(TenantController);
  }
}
