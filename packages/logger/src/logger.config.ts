import type { IncomingMessage, ServerResponse } from 'node:http';

import type { Params } from 'nestjs-pino';
import pino from 'pino';
import type { Options as PinoHttpOptions } from 'pino-http';

import { getClientIp, resolveCorrelationId } from './correlation-id';
import { CORRELATION_ID_HEADER, REQUEST_ID_HEADER, SUPPORTED_LOG_LEVELS } from './logger.constants';
import { createLoggerRedaction } from './logger.redaction';
import type {
  CorrelatedRequest,
  LoggerConfiguration,
  LoggerEnvironment,
  LogLevel,
  RuntimeEnvironment,
} from './logger.types';

function resolveEnvironment(value: string | undefined): RuntimeEnvironment {
  return value === 'production' || value === 'test' ? value : 'development';
}

function isLogLevel(value: string | undefined): value is LogLevel {
  return typeof value === 'string' && SUPPORTED_LOG_LEVELS.includes(value as LogLevel);
}

function resolveLogLevel(value: string | undefined, environment: RuntimeEnvironment): LogLevel {
  if (isLogLevel(value)) {
    return value;
  }

  return environment === 'production' ? 'info' : 'debug';
}

function readLoggerEnvironment(): LoggerEnvironment {
  return {
    APP_NAME: process.env.APP_NAME,
    LOG_LEVEL: process.env.LOG_LEVEL,
    NODE_ENV: process.env.NODE_ENV,
    SERVICE_NAME: process.env.SERVICE_NAME,
  };
}

export function resolveLoggerConfiguration(
  environment: LoggerEnvironment = readLoggerEnvironment(),
): LoggerConfiguration {
  const runtimeEnvironment = resolveEnvironment(environment.NODE_ENV);

  return {
    environment: runtimeEnvironment,
    level: resolveLogLevel(environment.LOG_LEVEL, runtimeEnvironment),
    pretty: runtimeEnvironment === 'development',
    serviceName: environment.SERVICE_NAME ?? environment.APP_NAME ?? 'nexoraa-service',
  };
}

function getRequestId(request: IncomingMessage): string {
  if (typeof request.id === 'string') {
    return request.id;
  }

  return typeof request.id === 'number' ? request.id.toString() : 'unknown';
}

export function createPinoHttpOptions(
  environment: LoggerEnvironment = readLoggerEnvironment(),
): PinoHttpOptions {
  const configuration = resolveLoggerConfiguration(environment);

  return {
    autoLogging: true,
    base: {
      environment: configuration.environment,
      service: configuration.serviceName,
    },
    customAttributeKeys: {
      reqId: 'requestId',
      responseTime: 'responseTimeMs',
    },
    customErrorMessage: () => 'request failed',
    customLogLevel: (_request, response, error): LogLevel => {
      if (error || response.statusCode >= 500) {
        return 'error';
      }

      return response.statusCode >= 400 ? 'warn' : 'info';
    },
    customProps: (request) => ({
      clientIp: getClientIp(request),
      correlationId: getRequestId(request),
    }),
    customReceivedMessage: () => 'request received',
    customSuccessMessage: () => 'request completed',
    genReqId: (request: IncomingMessage, response: ServerResponse): string => {
      const correlationId = resolveCorrelationId(request.headers);
      request.headers[CORRELATION_ID_HEADER] = correlationId;
      request.headers[REQUEST_ID_HEADER] = correlationId;
      response.setHeader(CORRELATION_ID_HEADER, correlationId);
      response.setHeader(REQUEST_ID_HEADER, correlationId);

      return correlationId;
    },
    level: configuration.level,
    redact: createLoggerRedaction(),
    serializers: {
      req: (request: CorrelatedRequest) => ({
        id: request.id,
        method: request.method,
        remoteAddress: getClientIp(request),
        url: request.url,
      }),
      res: (response: ServerResponse) => ({
        statusCode: response.statusCode,
      }),
    },
    timestamp: pino.stdTimeFunctions.isoTime,
    transport: configuration.pretty
      ? {
          options: {
            colorize: true,
            ignore: 'pid,hostname',
            singleLine: true,
            translateTime: 'SYS:standard',
          },
          target: 'pino-pretty',
        }
      : undefined,
  };
}

export function createLoggerModuleParams(
  environment: LoggerEnvironment = readLoggerEnvironment(),
): Params {
  return {
    assignResponse: true,
    pinoHttp: createPinoHttpOptions(environment),
  };
}
