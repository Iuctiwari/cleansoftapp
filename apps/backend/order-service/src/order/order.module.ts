import { Module } from '@nestjs/common';
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

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([
      { name: OrderMongoose.name, schema: OrderMongooseSchema },
      { name: CounterMongoose.name, schema: CounterMongooseSchema },
      { name: StatusHistoryMongoose.name, schema: StatusHistoryMongooseSchema },
      { name: AssignmentMongoose.name, schema: AssignmentMongooseSchema },
    ]),
  ],
})
export class OrderModule {}
