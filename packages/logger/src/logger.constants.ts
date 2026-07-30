export const CORRELATION_ID_HEADER = 'x-correlation-id';
export const REQUEST_ID_HEADER = 'x-request-id';
export const LOGGER_SERVICE_TOKEN = Symbol.for('@nexoraa/logger/service');
export const REDACTED_VALUE = '[REDACTED]';

export const SUPPORTED_LOG_LEVELS = [
  'fatal',
  'error',
  'warn',
  'info',
  'debug',
  'trace',
  'silent',
] as const;
