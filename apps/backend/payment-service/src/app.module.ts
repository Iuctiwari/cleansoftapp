import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppHealth } from './app.service';
import { PaymentModule } from './payments/payment.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      expandVariables: true,
      isGlobal: true,
    }),
    PaymentModule,
  ],
  controllers: [AppController],
  providers: [AppHealth],
})
export class AppModule {}
