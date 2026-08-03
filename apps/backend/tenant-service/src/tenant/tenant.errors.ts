import { HttpStatus } from '@nestjs/common';

export type TenantErrorCategory =
  | 'validation'
  | 'conflict'
  | 'not_found'
  | 'forbidden'
  | 'internal';

export interface TenantFieldError {
  readonly field: string;
  readonly code: string;
}

export interface TenantErrorDetails {
  code: string;
  category: TenantErrorCategory;
  messageKey: string;
  retryable?: boolean;
  fields?: readonly TenantFieldError[];
  cause?: Error;
}

export class TenantError extends Error {
  readonly code: string;
  readonly category: TenantErrorCategory;
  readonly messageKey: string;
  readonly retryable: boolean;
  readonly fields?: readonly TenantFieldError[];
  readonly statusCode: number;

  constructor(details: TenantErrorDetails) {
    super(details.messageKey, details.cause ? { cause: details.cause } : undefined);
    this.code = details.code;
    this.category = details.category;
    this.messageKey = details.messageKey;
    this.retryable = details.retryable ?? false;
    this.fields = details.fields;
    this.statusCode = mapCategoryToStatus(details.category);
  }
}

function mapCategoryToStatus(category: TenantErrorCategory): number {
  switch (category) {
    case 'validation':
      return HttpStatus.BAD_REQUEST;
    case 'conflict':
      return HttpStatus.CONFLICT;
    case 'not_found':
      return HttpStatus.NOT_FOUND;
    case 'forbidden':
      return HttpStatus.FORBIDDEN;
    case 'internal':
    default:
      return HttpStatus.INTERNAL_SERVER_ERROR;
  }
}
