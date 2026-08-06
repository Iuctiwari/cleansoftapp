import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth/auth.module';
import { PlatformModule } from './platform/platform.module';

@Module({
  imports: [ConfigModule.forRoot(), PlatformModule, AuthModule],
  controllers: [],
  providers: [],
})
export class AppModule {}
