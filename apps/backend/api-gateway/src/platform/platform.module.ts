import { Module } from '@nestjs/common';

import { PlatformDocsController } from './platform.docs';
import { PlatformHealthController, PlatformHealthService } from './platform.health';
import { TrustedContextFactory } from './platform.context';

@Module({
  controllers: [PlatformHealthController, PlatformDocsController],
  providers: [PlatformHealthService, TrustedContextFactory],
  exports: [TrustedContextFactory],
})
export class PlatformModule {}
