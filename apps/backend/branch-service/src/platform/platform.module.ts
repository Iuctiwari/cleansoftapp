import { Module } from '@nestjs/common';

import { TrustedContextFactory } from './platform.context';

@Module({
  providers: [TrustedContextFactory],
  exports: [TrustedContextFactory],
})
export class PlatformModule {}
