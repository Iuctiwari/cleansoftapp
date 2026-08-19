import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { ExpenseController } from './expense.controller';
import { ExpenseAuthenticationMiddleware } from './expense-auth.middleware';
import { ExpenseScopeGuard } from './expense.guard';
import { MongoExpenseRepository } from './expense.mongo.repository';
import { ExpenseService } from './expense.service';
import { EXPENSE_REPOSITORY } from './expense.types';

@Module({
  imports: [ConfigModule],
  controllers: [ExpenseController],
  providers: [
    ExpenseService,
    ExpenseAuthenticationMiddleware,
    ExpenseScopeGuard,
    MongoExpenseRepository,
    { provide: EXPENSE_REPOSITORY, useExisting: MongoExpenseRepository },
  ],
  exports: [ExpenseService, EXPENSE_REPOSITORY],
})
export class ExpenseModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(ExpenseAuthenticationMiddleware).forRoutes(ExpenseController);
  }
}
