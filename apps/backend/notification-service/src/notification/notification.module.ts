import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { DatabaseModule } from '@nexoraa/database';

import { NotificationAuthenticationMiddleware } from './notification-auth.middleware';
import { NotificationAuthResolver } from './notification-auth.resolver';
import { NotificationController } from './notification.controller';
import { NotificationGateway } from './notification.gateway';
import { NotificationMongoose, NotificationMongooseSchema } from './notification.schema';
import { NotificationService } from './notification.service';
import { FcmSender } from '../push/fcm.sender';
import { PushDeviceMongoose, PushDeviceMongooseSchema } from '../push/push-device.schema';
import {
  ConsumerPushAuthMiddleware,
  ConsumerPushDeviceController,
  PushDeviceController,
  PushInternalController,
} from '../push/push.controllers';
import { PushService } from '../push/push.service';

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    MongooseModule.forFeature([
      { name: NotificationMongoose.name, schema: NotificationMongooseSchema },
      { name: PushDeviceMongoose.name, schema: PushDeviceMongooseSchema },
    ]),
  ],
  controllers: [
    NotificationController,
    PushDeviceController,
    ConsumerPushDeviceController,
    PushInternalController,
  ],
  providers: [
    NotificationAuthResolver,
    NotificationAuthenticationMiddleware,
    NotificationGateway,
    NotificationService,
    ConsumerPushAuthMiddleware,
    FcmSender,
    PushService,
  ],
  exports: [MongooseModule, NotificationService, PushService],
})
export class NotificationModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer
      .apply(NotificationAuthenticationMiddleware)
      .forRoutes(NotificationController, PushDeviceController);
    consumer.apply(ConsumerPushAuthMiddleware).forRoutes(ConsumerPushDeviceController);
  }
}
