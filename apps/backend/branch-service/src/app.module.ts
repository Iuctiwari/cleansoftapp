import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from '@nexoraa/database';

import { AppController } from './app.controller';
import { AppHealth } from './app.service';
import { BranchModule } from './branches/branch.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      cache: true,
      expandVariables: true,
      isGlobal: true,
    }),
    DatabaseModule,
    BranchModule,
  ],
  controllers: [AppController],
  providers: [AppHealth],
})
export class AppModule {}
