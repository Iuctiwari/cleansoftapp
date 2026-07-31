import { Injectable } from '@nestjs/common';
import type { Clock } from '@nexoraa/shared';

@Injectable()
export class SystemClock implements Clock {
  now(): Date {
    return new Date();
  }
}
