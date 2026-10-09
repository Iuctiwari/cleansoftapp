import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';

import {
  AssignmentMongoose,
  AssignmentMongooseSchema,
  CounterMongoose,
  CounterMongooseSchema,
  OrderMongoose,
  OrderMongooseSchema,
  StatusHistoryMongoose,
  StatusHistoryMongooseSchema,
} from './order.schema';
import { OrderAuditService } from './order-audit.service';
import { OrderAuthenticationMiddleware } from './order-auth.middleware';
import { OrderController } from './order.controller';
import { OrderInternalController } from './order-internal.controller';
import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';
import { OrderScopeGuard } from './order.guard';
import { OrderIdPipe } from './order-id.pipe';
import { HttpOrderDependencies } from './order.integrations';
import { MongoOrderRepository } from './order.mongo.repository';
import { OrderOwnerLookupService } from './order-owner.service';
import { TenantOwnerMongoose, TenantOwnerMongooseSchema } from './order-owner.schema';
import { OrderOverdueController } from './order-overdue.controller';
import { OrderOverdueService } from './order-overdue.service';
import { OrderService } from './order.service';
import { ORDER_DEPENDENCIES, ORDER_REPOSITORY } from './order.types';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    MongooseModule.forFeature([
      { name: OrderMongoose.name, schema: OrderMongooseSchema },
      { name: CounterMongoose.name, schema: CounterMongooseSchema },
      { name: StatusHistoryMongoose.name, schema: StatusHistoryMongooseSchema },
      { name: AssignmentMongoose.name, schema: AssignmentMongooseSchema },
      { name: TenantOwnerMongoose.name, schema: TenantOwnerMongooseSchema },
    ]),
  ],
  controllers: [OrderController, OrderInternalController, OrderOverdueController],
  providers: [
    OrderService,
    OrderAuditService,
    OrderAuthenticationMiddleware,
    OrderScopeGuard,
    PlatformAdminInternalGuard,
    OrderIdPipe,
    MongoOrderRepository,
    { provide: ORDER_REPOSITORY, useExisting: MongoOrderRepository },
    HttpOrderDependencies,
    { provide: ORDER_DEPENDENCIES, useExisting: HttpOrderDependencies },
    OrderOwnerLookupService,
    OrderOverdueService,
  ],
  exports: [OrderService],
})
export class OrderModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(OrderAuthenticationMiddleware).forRoutes(OrderController);
  }
}
