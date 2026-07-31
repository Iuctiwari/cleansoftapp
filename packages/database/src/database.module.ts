import { Global, Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { TerminusModule } from '@nestjs/terminus';

import { DatabaseHealth } from './database.health';
import { DatabaseLifecycle } from './database.lifecycle';
import { createMongooseOptions } from './database.options';

@Global()
@Module({
  imports: [
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: createMongooseOptions,
    }),
    TerminusModule,
  ],
  providers: [DatabaseHealth, DatabaseLifecycle],
  exports: [DatabaseHealth, MongooseModule, TerminusModule],
})
export class DatabaseModule {}
