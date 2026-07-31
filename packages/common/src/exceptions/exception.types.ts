import type { EXCEPTION_CODES } from './exception.constants';

export type StandardExceptionCode = (typeof EXCEPTION_CODES)[keyof typeof EXCEPTION_CODES];

export interface ValidationErrorDetails {
  readonly errors: readonly string[];
}

export interface StandardErrorResponse {
  readonly statusCode: number;
  readonly code: string;
  readonly message: string;
  readonly timestamp: string;
  readonly path: string;
  readonly method: string;
  readonly correlationId?: string;
  readonly details?: unknown;
}

export interface ExceptionRequest {
  readonly headers?: Readonly<Record<string, string | string[] | undefined>>;
  readonly id?: string | number;
  readonly method?: string;
  readonly originalUrl?: string;
  readonly url?: string;
}

export interface ExceptionRequestContext {
  readonly correlationId?: string;
  readonly method?: string;
  readonly path?: string;
}

export interface ResolvedException {
  readonly statusCode: number;
  readonly code: string;
  readonly message: string;
  readonly details?: unknown;
}
