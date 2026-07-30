import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { createGatewayEnvironmentConfig } from '@nexoraa/config';
import { DatabaseModule } from '@nexoraa/database';

import { AppController } from './app.controller';
import { AppHealth } from './app.service';

@Module({
  imports: [ConfigModule.forRoot(createGatewayEnvironmentConfig()), DatabaseModule],
  controllers: [AppController],
  providers: [AppHealth],
})
export class AppModule {}
