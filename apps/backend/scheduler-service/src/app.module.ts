import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AppController } from './app.controller';
import { AppHealth } from './app.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      expandVariables: true,
      isGlobal: true,
    }),
  ],
  controllers: [AppController],
  providers: [AppHealth],
})
export class AppModule {}
