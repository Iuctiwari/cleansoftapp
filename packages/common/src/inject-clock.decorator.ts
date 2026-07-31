import { Inject } from '@nestjs/common';
import { CLOCK_TOKEN } from '@nexoraa/shared';

export function InjectClock(): ParameterDecorator {
  return Inject(CLOCK_TOKEN);
}
