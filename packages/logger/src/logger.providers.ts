import type { Provider } from '@nestjs/common';

import { LOGGER_SERVICE_TOKEN } from './logger.constants';
import { LoggerService } from './logger.service';

export const LOGGER_PROVIDERS: readonly Provider[] = [
  LoggerService,
  {
    provide: LOGGER_SERVICE_TOKEN,
    useExisting: LoggerService,
  },
];
