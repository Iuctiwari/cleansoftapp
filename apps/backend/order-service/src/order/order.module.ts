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
import { OrderScopeGuard } from './order.guard';
import { OrderIdPipe } from './order-id.pipe';
import { HttpOrderDependencies } from './order.integrations';
import { MongoOrderRepository } from './order.mongo.repository';
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
    ]),
  ],
  controllers: [OrderController],
  providers: [
    OrderService,
    OrderAuditService,
    OrderAuthenticationMiddleware,
    OrderScopeGuard,
    OrderIdPipe,
    MongoOrderRepository,
    { provide: ORDER_REPOSITORY, useExisting: MongoOrderRepository },
    HttpOrderDependencies,
    { provide: ORDER_DEPENDENCIES, useExisting: HttpOrderDependencies },
  ],
})
export class OrderModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(OrderAuthenticationMiddleware).forRoutes(OrderController);
  }
}
