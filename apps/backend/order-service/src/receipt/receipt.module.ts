import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { OrderAuthenticationMiddleware } from '../order/order-auth.middleware';
import { OrderIdPipe } from '../order/order-id.pipe';
import { OrderScopeGuard } from '../order/order.guard';
import { OrderModule } from '../order/order.module';
import { ReceiptBranchClient } from './receipt-branch.client';
import { ReceiptController } from './receipt.controller';
import { ReceiptService } from './receipt.service';

/**
 * OrderAuthenticationMiddleware and OrderScopeGuard are the same classes the
 * Order module uses (imported, not reimplemented) so the receipt route is
 * authenticated and tenant/branch scoped identically to the rest of the
 * Order API. OrderModule is imported only for its exported OrderService.
 */
@Module({
  imports: [ConfigModule, OrderModule],
  controllers: [ReceiptController],
  providers: [
    ReceiptService,
    ReceiptBranchClient,
    OrderAuthenticationMiddleware,
    OrderScopeGuard,
    OrderIdPipe,
  ],
})
export class ReceiptModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(OrderAuthenticationMiddleware).forRoutes(ReceiptController);
  }
}
