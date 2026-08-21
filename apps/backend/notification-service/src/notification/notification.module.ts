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

@Module({
  imports: [
    ConfigModule,
    DatabaseModule,
    MongooseModule.forFeature([
      { name: NotificationMongoose.name, schema: NotificationMongooseSchema },
    ]),
  ],
  controllers: [NotificationController],
  providers: [
    NotificationAuthResolver,
    NotificationAuthenticationMiddleware,
    NotificationGateway,
    NotificationService,
  ],
  exports: [MongooseModule, NotificationService],
})
export class NotificationModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(NotificationAuthenticationMiddleware).forRoutes(NotificationController);
  }
}
