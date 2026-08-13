import { randomUUID } from 'node:crypto';

export const TRUSTED_CONTEXT_TOKEN = Symbol('TRUSTED_CONTEXT_TOKEN');

export type ErrorCategory =
  | 'validation'
  | 'unauthenticated'
  | 'forbidden'
  | 'not_found'
  | 'conflict'
  | 'rate_limit'
  | 'dependency_unavailable'
  | 'timeout'
  | 'internal';

export type SupportAccessMode = 'read_only' | 'break_glass';
export type ScopeKind = 'platform' | 'tenant' | 'support';

export interface CorrelationContext {
  readonly correlationId: string;
  readonly causationId: string;
  readonly requestId: string;
}

export interface ActorContext {
  readonly actorId: string;
  readonly actorType: 'user' | 'service' | 'support';
}

export interface PlatformContext extends CorrelationContext, ActorContext {
  readonly kind: 'platform';
  readonly sessionId?: string;
  readonly roleCode?: string;
  readonly permissions?: readonly string[];
  readonly accessVersion?: number;
  readonly [TRUSTED_CONTEXT_TOKEN]: true;
}

export interface TenantContext extends CorrelationContext, ActorContext {
  readonly kind: 'tenant';
  readonly tenantId: string;
  readonly branchId?: string;
  readonly sessionId?: string;
  readonly permissions: readonly string[];
  readonly accessVersion: number;
  readonly roleCode?: string;
  readonly [TRUSTED_CONTEXT_TOKEN]: true;
}

export interface SupportContext extends CorrelationContext, ActorContext {
  readonly kind: 'support';
  readonly supportAccessMode: SupportAccessMode;
  readonly platformOperatorId: string;
  readonly tenantId: string;
  readonly branchId?: string;
  readonly sessionId?: string;
  readonly reason: string;
  readonly [TRUSTED_CONTEXT_TOKEN]: true;
}

export type TrustedContext = PlatformContext | TenantContext | SupportContext;

export interface PaginationQuery {
  readonly page: number;
  readonly pageSize: number;
}

export interface PaginatedResult<TItem> {
  readonly items: readonly TItem[];
  readonly page: number;
  readonly pageSize: number;
  readonly total: number;
}

export interface ApiSuccessMeta {
  readonly page?: number;
  readonly pageSize?: number;
  readonly total?: number;
  readonly correlationId: string;
}

export interface ApiSuccessEnvelope<TData> {
  readonly data: TData;
  readonly meta?: ApiSuccessMeta;
}

export interface ApiFieldError {
  readonly field: string;
  readonly code: string;
}

export interface ApiErrorEnvelope {
  readonly error: {
    readonly code: string;
    readonly category: ErrorCategory;
    readonly messageKey: string;
    readonly fields?: readonly ApiFieldError[];
    readonly retryable: boolean;
    readonly correlationId: string;
  };
}

export interface PublicErrorDetails {
  readonly code: string;
  readonly category: ErrorCategory;
  readonly messageKey: string;
  readonly retryable: boolean;
  readonly fields?: readonly ApiFieldError[];
}

export interface ContractVersion {
  readonly major: number;
  readonly minor: number;
}

export function createCorrelationContext(
  overrides: Partial<CorrelationContext> = {},
): CorrelationContext {
  return {
    correlationId: overrides.correlationId ?? randomUUID(),
    causationId: overrides.causationId ?? randomUUID(),
    requestId: overrides.requestId ?? randomUUID(),
  };
}
