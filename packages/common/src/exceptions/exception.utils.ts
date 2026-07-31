import { HttpException, HttpStatus } from '@nestjs/common';

import { ApplicationException } from './application.exception';
import {
  DEFAULT_ERROR_PATH,
  DEFAULT_HTTP_METHOD,
  EXCEPTION_CODES,
  EXCEPTION_MESSAGES,
} from './exception.constants';
import type {
  ExceptionRequest,
  ExceptionRequestContext,
  ResolvedException,
  StandardErrorResponse,
  ValidationErrorDetails,
} from './exception.types';

const BAD_REQUEST_STATUS: number = HttpStatus.BAD_REQUEST;
const INTERNAL_SERVER_ERROR_STATUS: number = HttpStatus.INTERNAL_SERVER_ERROR;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function normalizeIdentifier(value: unknown): string | undefined {
  if (typeof value === 'number') {
    return value.toString();
  }

  if (typeof value !== 'string') {
    return undefined;
  }

  const normalized = value.trim();
  return normalized.length > 0 ? normalized : undefined;
}

function firstHeaderValue(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

function validationDetails(response: unknown): ValidationErrorDetails | undefined {
  if (!isRecord(response) || !Array.isArray(response.message)) {
    return undefined;
  }

  const errors = response.message.filter(
    (message): message is string => typeof message === 'string',
  );

  return errors.length > 0 ? { errors } : undefined;
}

function responseMessage(response: unknown, fallback: string): string {
  if (typeof response === 'string') {
    return response;
  }

  if (isRecord(response) && typeof response.message === 'string') {
    return response.message;
  }

  return fallback;
}

function responseCode(response: unknown, statusCode: number): string {
  if (isRecord(response) && typeof response.code === 'string') {
    return response.code;
  }

  return statusCode === INTERNAL_SERVER_ERROR_STATUS
    ? EXCEPTION_CODES.INTERNAL_SERVER_ERROR
    : `${EXCEPTION_CODES.HTTP_ERROR}_${statusCode}`;
}

function responseDetails(response: unknown): unknown {
  return isRecord(response) ? response.details : undefined;
}

export function getExceptionRequestContext(request: ExceptionRequest): ExceptionRequestContext {
  const headers = request.headers;
  const correlationId =
    normalizeIdentifier(request.id) ??
    normalizeIdentifier(firstHeaderValue(headers?.['x-correlation-id'])) ??
    normalizeIdentifier(firstHeaderValue(headers?.['x-request-id']));

  return {
    correlationId,
    method: request.method,
    path: request.originalUrl ?? request.url,
  };
}

export function resolveException(exception: unknown): ResolvedException {
  if (exception instanceof ApplicationException) {
    return {
      code: exception.code,
      details: exception.details,
      message: exception.message,
      statusCode: exception.statusCode,
    };
  }

  if (exception instanceof HttpException) {
    const statusCode = exception.getStatus();
    const response = exception.getResponse();
    const validation = validationDetails(response);

    if (statusCode === BAD_REQUEST_STATUS && validation) {
      return {
        code: EXCEPTION_CODES.VALIDATION_ERROR,
        details: validation,
        message: EXCEPTION_MESSAGES.VALIDATION_ERROR,
        statusCode,
      };
    }

    if (statusCode >= INTERNAL_SERVER_ERROR_STATUS) {
      return {
        code: EXCEPTION_CODES.INTERNAL_SERVER_ERROR,
        message: EXCEPTION_MESSAGES.INTERNAL_SERVER_ERROR,
        statusCode,
      };
    }

    return {
      code: responseCode(response, statusCode),
      details: responseDetails(response),
      message: responseMessage(response, exception.message),
      statusCode,
    };
  }

  return {
    code: EXCEPTION_CODES.INTERNAL_SERVER_ERROR,
    message: EXCEPTION_MESSAGES.INTERNAL_SERVER_ERROR,
    statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
  };
}

export function createStandardErrorResponse(
  exception: unknown,
  context: ExceptionRequestContext = {},
  timestamp: Date = new Date(),
): StandardErrorResponse {
  const resolved = resolveException(exception);

  return {
    code: resolved.code,
    correlationId: context.correlationId,
    details: resolved.details,
    message: resolved.message,
    method: context.method ?? DEFAULT_HTTP_METHOD,
    path: context.path ?? DEFAULT_ERROR_PATH,
    statusCode: resolved.statusCode,
    timestamp: timestamp.toISOString(),
  };
}
