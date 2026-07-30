import { HttpException, HttpStatus } from '@nestjs/common';

import type { ApiFieldError, ErrorCategory, PublicErrorDetails } from './platform.types';

export class PlatformError extends Error {
  readonly code: string;
  readonly category: ErrorCategory;
  readonly messageKey: string;
  readonly retryable: boolean;
  readonly fields?: readonly ApiFieldError[];
  readonly statusCode: number;

  constructor(details: {
    code: string;
    category: ErrorCategory;
    messageKey: string;
    retryable?: boolean;
    fields?: readonly ApiFieldError[];
    statusCode?: number;
    cause?: Error;
  }) {
    super(details.messageKey, details.cause ? { cause: details.cause } : undefined);
    this.code = details.code;
    this.category = details.category;
    this.messageKey = details.messageKey;
    this.retryable = details.retryable ?? false;
    this.fields = details.fields;
    this.statusCode = details.statusCode ?? mapCategoryToStatus(details.category);
  }

  toPublicDetails(): PublicErrorDetails {
    return {
      code: this.code,
      category: this.category,
      messageKey: this.messageKey,
      retryable: this.retryable,
      fields: this.fields,
    };
  }
}

export function mapCategoryToStatus(category: ErrorCategory): number {
  switch (category) {
    case 'validation':
      return HttpStatus.BAD_REQUEST;
    case 'unauthenticated':
      return HttpStatus.UNAUTHORIZED;
    case 'forbidden':
      return HttpStatus.FORBIDDEN;
    case 'not_found':
      return HttpStatus.NOT_FOUND;
    case 'conflict':
      return HttpStatus.CONFLICT;
    case 'rate_limit':
      return HttpStatus.TOO_MANY_REQUESTS;
    case 'dependency_unavailable':
      return HttpStatus.BAD_GATEWAY;
    case 'timeout':
      return HttpStatus.GATEWAY_TIMEOUT;
    case 'internal':
    default:
      return HttpStatus.INTERNAL_SERVER_ERROR;
  }
}

export function toPlatformError(error: unknown): PlatformError {
  if (error instanceof PlatformError) {
    return error;
  }

  if (error instanceof HttpException) {
    return new PlatformError({
      code: 'platform.http_exception',
      category: 'internal',
      messageKey: 'errors.internal',
      statusCode: error.getStatus(),
    });
  }

  return new PlatformError({
    code: 'platform.internal',
    category: 'internal',
    messageKey: 'errors.internal',
    retryable: false,
    cause: error instanceof Error ? error : undefined,
  });
}
