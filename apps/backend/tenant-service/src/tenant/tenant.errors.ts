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

/**
 * Turns a MongoDB duplicate-key error (E11000) into a 409 TenantError naming the
 * field, so the app can say "Mobile number is already registered" instead of a
 * 500. Owner phone (tenants.ownerPhone, owners.mobileNumber) and email are
 * unique across the platform. Returns undefined for any other error.
 */
export function duplicateKeyToTenantError(error: unknown): TenantError | undefined {
  const mongoError = error as { code?: number; keyPattern?: Record<string, unknown> };
  if (mongoError?.code !== 11000) return undefined;
  const key = Object.keys(mongoError.keyPattern ?? {})[0] ?? '';
  const [field, code] = /phone|mobile/i.test(key)
    ? ['mobileNumber', 'tenant.mobile_already_registered']
    : /email/i.test(key)
      ? ['email', 'tenant.email_already_registered']
      : ['account', 'tenant.already_exists'];
  return new TenantError({
    code,
    category: 'conflict',
    messageKey: `errors.${code}`,
    fields: [{ field, code }],
    cause: error as Error,
  });
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
