import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';

import { UserController } from './user.controller';
import { UserMongoose, UserMongooseSchema } from './user.schema';
import { UserService } from './user.service';

@Module({
  imports: [
    ConfigModule,
    MongooseModule.forFeature([{ name: UserMongoose.name, schema: UserMongooseSchema }]),
  ],
  controllers: [UserController],
  providers: [UserService],
  exports: [UserService],
})
export class UserModule {}

