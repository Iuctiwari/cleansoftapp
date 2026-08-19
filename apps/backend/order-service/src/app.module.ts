import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER } from '@nestjs/core';
import { GlobalExceptionFilter } from '@nexoraa/common';

import { AppController } from './app.controller';
import { AppHealth } from './app.service';
import { OrderModule } from './order/order.module';
import { ReceiptModule } from './receipt/receipt.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      expandVariables: true,
      isGlobal: true,
    }),
    OrderModule,
    ReceiptModule,
  ],
  controllers: [AppController],
  providers: [AppHealth, { provide: APP_FILTER, useClass: GlobalExceptionFilter }],
})
export class AppModule {}
