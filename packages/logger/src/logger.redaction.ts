import { REDACTED_VALUE } from './logger.constants';

export const SENSITIVE_LOG_PATHS = [
  'password',
  'token',
  'authorization',
  'cookie',
  'refreshToken',
  'accessToken',
  'req.headers.authorization',
  'req.headers.cookie',
  'req.body.password',
  'req.body.token',
  'req.body.authorization',
  'req.body.cookie',
  'req.body.refreshToken',
  'req.body.accessToken',
  'request.headers.authorization',
  'request.headers.cookie',
  'request.body.password',
  'request.body.token',
  'request.body.authorization',
  'request.body.cookie',
  'request.body.refreshToken',
  'request.body.accessToken',
  'res.headers.set-cookie',
  'response.headers.set-cookie',
] as const;

export interface LoggerRedaction {
  readonly censor: string;
  readonly paths: string[];
}

export function createLoggerRedaction(): LoggerRedaction {
  return {
    censor: REDACTED_VALUE,
    paths: [...SENSITIVE_LOG_PATHS],
  };
}
