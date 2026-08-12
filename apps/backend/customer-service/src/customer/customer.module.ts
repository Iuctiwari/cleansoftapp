import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';

import { CustomerController } from './customer.controller';
import { CustomerAuthenticationMiddleware } from './customer-auth.middleware';
import { CustomerScopeGuard } from './customer.guard';
import { CustomerMongoose, CustomerMongooseSchema } from './customer.mongoose.schema';
import { MongoCustomerRepository } from './customer.mongo.repository';
import { CustomerService } from './customer.service';
import { CUSTOMER_REPOSITORY } from './customer.types';

@Module({
  imports: [
    DatabaseModule,
    MongooseModule.forFeature([{ name: CustomerMongoose.name, schema: CustomerMongooseSchema }]),
  ],
  controllers: [CustomerController],
  providers: [
    CustomerService,
    CustomerAuthenticationMiddleware,
    CustomerScopeGuard,
    MongoCustomerRepository,
    { provide: CUSTOMER_REPOSITORY, useExisting: MongoCustomerRepository },
  ],
})
export class CustomerModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(CustomerAuthenticationMiddleware).forRoutes(CustomerController);
  }
}
