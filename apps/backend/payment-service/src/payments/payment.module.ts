import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';

import { PaymentAuthenticationMiddleware } from './payment-auth.middleware';
import { PaymentController } from './payment.controller';
import { PaymentInternalController } from './payment-internal.controller';
import { PlatformAdminInternalGuard } from './platform-admin-internal.guard';
import { PaymentOwnerLookupService } from './payment-owner.service';
import { TenantOwnerMongoose, TenantOwnerMongooseSchema } from './payment-owner.schema';
import { PaymentMongoose, PaymentMongooseSchema } from './payment.schema';
import { PaymentService } from './payment.service';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    MongooseModule.forFeature([
      { name: PaymentMongoose.name, schema: PaymentMongooseSchema },
      { name: TenantOwnerMongoose.name, schema: TenantOwnerMongooseSchema },
    ]),
  ],
  controllers: [PaymentController, PaymentInternalController],
  providers: [
    PaymentAuthenticationMiddleware,
    PaymentService,
    PaymentOwnerLookupService,
    PlatformAdminInternalGuard,
  ],
})
export class PaymentModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(PaymentAuthenticationMiddleware).forRoutes(PaymentController);
  }
}
