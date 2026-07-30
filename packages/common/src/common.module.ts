import { Module } from '@nestjs/common';
import { CLOCK_TOKEN } from '@nexoraa/shared';

import { SystemClock } from './system-clock';

@Module({
  providers: [{ provide: CLOCK_TOKEN, useClass: SystemClock }],
  exports: [CLOCK_TOKEN],
})
export class CommonModule {}
