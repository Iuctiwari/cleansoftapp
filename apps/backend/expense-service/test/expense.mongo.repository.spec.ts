import 'reflect-metadata';

import { ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { ExpensePaymentMethod } from '../src/expense/expense.mongoose.schema';
import { MongoExpenseRepository } from '../src/expense/expense.mongo.repository';
import type { ExpenseScope } from '../src/expense/expense.types';

describe('MongoExpenseRepository persistence availability', () => {
  const scope: ExpenseScope = {
    actorId: '64f0c18f7c4d2f0012ab34bb',
    tenantId: '64f0c18f7c4d2f0012ab34aa',
    branchId: 'branch-a',
    roleCode: 'Owner',
    permissions: [],
  };

  it('does not return a successful create response when MongoDB is unavailable', async () => {
    const repository = new MongoExpenseRepository(
      new ConfigService({
        MONGODB_URI: 'mongodb://127.0.0.1:1/nexoraa_unavailable',
      }),
    );

    await repository.onModuleInit();

    await expect(
      repository.createExpense(scope, {
        expenseCategoryId: '64f0c18f7c4d2f0012ab34cd',
        amount: 100,
        paymentMethod: ExpensePaymentMethod.CASH,
        vendor: 'Power Co',
        description: 'Electricity bill',
      }),
    ).rejects.toThrow(ServiceUnavailableException);
  });
});
