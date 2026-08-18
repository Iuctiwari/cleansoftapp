import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER } from '@nestjs/core';
import { GlobalExceptionFilter } from '@nexoraa/common';

import { AppController } from './app.controller';
import { AppHealth } from './app.service';
import { CatalogModule } from './catalog/catalog.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      expandVariables: true,
      isGlobal: true,
    }),
    CatalogModule,
  ],
  controllers: [AppController],
  providers: [AppHealth, { provide: APP_FILTER, useClass: GlobalExceptionFilter }],
})
export class AppModule {}
