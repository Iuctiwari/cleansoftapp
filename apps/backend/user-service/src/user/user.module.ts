import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

import { UserController } from './user.controller';
import { UserMongoose, UserMongooseSchema } from './user.schema';
import { UserService } from './user.service';
import { UserAuthenticationMiddleware } from './user-auth.middleware';

@Module({
  imports: [
    ConfigModule,
    MongooseModule.forFeature([{ name: UserMongoose.name, schema: UserMongooseSchema }]),
  ],
  controllers: [UserController],
  providers: [UserService, UserAuthenticationMiddleware],
  exports: [UserService],
})
export class UserModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    consumer.apply(UserAuthenticationMiddleware).forRoutes(UserController);
  }
}
