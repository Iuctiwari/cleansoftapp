import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { PlatformDocsController } from './platform.docs';
import { PlatformHealthController, PlatformHealthService } from './platform.health';
import { TrustedContextFactory } from './platform.context';

@Module({
  imports: [ConfigModule],
  controllers: [PlatformHealthController, PlatformDocsController],
  providers: [PlatformHealthService, TrustedContextFactory],
  exports: [TrustedContextFactory],
})
export class PlatformModule {}
