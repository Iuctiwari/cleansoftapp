import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

import { PlatformModule } from '../platform/platform.module';
import { TrustedContextMiddleware } from '../platform/platform.auth.middleware';
import { BranchController } from './branch.controller';
import {
  ConfiguredBranchLimitProvider,
  MongoManagerEligibilityService,
  NullOrdersGateway,
} from './branch.collaborators';
import { MongoBranchRepository } from './branch.mongo.repository';
import {
  BranchMongoose,
  BranchMongooseSchema,
  ManagerCandidateMongoose,
  ManagerCandidateMongooseSchema,
} from './branch.mongoose.schema';
import { BranchService } from './branch.service';
import {
  BRANCH_LIMIT_PROVIDER,
  BRANCH_REPOSITORY,
  MANAGER_ELIGIBILITY_SERVICE,
  ORDERS_GATEWAY,
} from './branch.types';

@Module({
  imports: [
    ConfigModule,
    PlatformModule,
    MongooseModule.forFeature([
      { name: BranchMongoose.name, schema: BranchMongooseSchema },
      { name: ManagerCandidateMongoose.name, schema: ManagerCandidateMongooseSchema },
    ]),
  ],
  controllers: [BranchController],
  providers: [
    BranchService,
    MongoBranchRepository,
    { provide: BRANCH_REPOSITORY, useExisting: MongoBranchRepository },
    MongoManagerEligibilityService,
    { provide: MANAGER_ELIGIBILITY_SERVICE, useExisting: MongoManagerEligibilityService },
    ConfiguredBranchLimitProvider,
    { provide: BRANCH_LIMIT_PROVIDER, useExisting: ConfiguredBranchLimitProvider },
    NullOrdersGateway,
    { provide: ORDERS_GATEWAY, useExisting: NullOrdersGateway },
    TrustedContextMiddleware,
  ],
})
export class BranchModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(TrustedContextMiddleware).forRoutes(BranchController);
  }
}
