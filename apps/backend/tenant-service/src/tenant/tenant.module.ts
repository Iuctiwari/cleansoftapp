import { Module } from '@nestjs/common';
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
import { MongoTenantRepository } from './tenant.mongo.repository';
import { InMemoryTenantRepository } from './tenant.repository';
import { TenantService } from './tenant.service';
import { TENANT_REPOSITORY } from './tenant.types';

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
    // MongoDB-backed repository — active by default.
    MongoTenantRepository,
    {
      provide: TENANT_REPOSITORY,
      useExisting: MongoTenantRepository,
    },
    // In-memory repository kept available for unit tests.
    InMemoryTenantRepository,
  ],
  exports: [TenantService],
})
export class TenantModule {}
