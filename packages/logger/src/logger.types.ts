import type { IncomingMessage } from 'node:http';

import type { ReqId } from 'pino-http';

import type { SUPPORTED_LOG_LEVELS } from './logger.constants';

export type LogLevel = (typeof SUPPORTED_LOG_LEVELS)[number];
export type RuntimeEnvironment = 'development' | 'production' | 'test';

export interface LoggerEnvironment {
  readonly APP_NAME?: string;
  readonly LOG_LEVEL?: string;
  readonly NODE_ENV?: string;
  readonly SERVICE_NAME?: string;
}

export interface LoggerConfiguration {
  readonly environment: RuntimeEnvironment;
  readonly level: LogLevel;
  readonly pretty: boolean;
  readonly serviceName: string;
}

export interface CorrelatedRequest extends IncomingMessage {
  id: ReqId;
}
