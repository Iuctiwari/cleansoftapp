import type {
  AuditObligationReference,
  ContractVersion,
  PaginatedResult,
  PlatformContext,
  SupportAuthorization,
  SupportContext,
  TenantContext,
} from '../platform/platform.types';

export type AuditClassification = 'security' | 'financial' | 'operational' | 'compliance';
export type AuditResult = 'accepted' | 'committed' | 'replayed';
export type AuditAuthorization = PlatformContext | TenantContext | SupportContext;

export interface AuditActorSnapshot {
  readonly actorId: string;
  readonly actorType: 'user' | 'service' | 'support';
}

export interface AuditTargetSnapshot {
  readonly targetId: string;
  readonly targetType: string;
}

export interface AuditRetentionTag {
  readonly code: string;
  readonly label: string;
}

export interface AuditSummary {
  readonly fields: Record<string, string | number | boolean | null>;
}

export interface AuditRecordInput extends AuditObligationReference {
  readonly module: string;
  readonly action: string;
  readonly classification: AuditClassification;
  readonly actor: AuditActorSnapshot;
  readonly target: AuditTargetSnapshot;
  readonly context: AuditAuthorization;
  readonly oldSummary?: AuditSummary;
  readonly newSummary?: AuditSummary;
  readonly retentionTags: readonly AuditRetentionTag[];
  readonly contractVersion: ContractVersion;
}

export interface AuditRecord {
  readonly auditId: string;
  readonly scopeKind: 'platform' | 'tenant' | 'support';
  readonly tenantId?: string;
  readonly branchId?: string;
  readonly actor: AuditActorSnapshot;
  readonly module: string;
  readonly action: string;
  readonly target: AuditTargetSnapshot;
  readonly classification: AuditClassification;
  readonly occurredAtUtc: string;
  readonly correlationId: string;
  readonly causationId: string;
  readonly requestId: string;
  readonly result: AuditResult;
  readonly sourceObligation: string;
  readonly oldSummary?: AuditSummary;
  readonly newSummary?: AuditSummary;
  readonly retentionTags: readonly AuditRetentionTag[];
  readonly contractVersion: ContractVersion;
}

export interface AuditQueryFilters {
  readonly module?: string;
  readonly action?: string;
  readonly actorId?: string;
  readonly targetId?: string;
  readonly classification?: AuditClassification;
  readonly tenantId?: string;
}

export interface AuditExportIntent {
  readonly exportId: string;
  readonly requestedAtUtc: string;
  readonly idempotencyKey: string;
  readonly filters: AuditQueryFilters;
  readonly authorizationKind: AuditAuthorization['kind'];
}

export interface AuditRecordOutcome {
  readonly auditId: string;
  readonly result: AuditResult;
}

export interface AuditRepository {
  record(record: AuditRecordInput): Promise<AuditRecordOutcome>;
  getById(auditId: string): Promise<AuditRecord | null>;
  query(
    authorization: AuditAuthorization,
    filters: AuditQueryFilters,
    page: { page: number; pageSize: number },
  ): Promise<PaginatedResult<AuditRecord>>;
  requestExport(
    authorization: AuditAuthorization,
    filters: AuditQueryFilters,
    idempotencyKey: string,
  ): Promise<AuditExportIntent>;
}

export interface AuditServiceContract {
  recordAudit(obligation: AuditRecordInput): Promise<AuditRecordOutcome>;
  queryAudit(
    authorization: AuditAuthorization,
    filters: AuditQueryFilters,
    page: { page: number; pageSize: number },
  ): Promise<PaginatedResult<AuditRecord>>;
  getAuditById(authorization: AuditAuthorization, auditId: string): Promise<AuditRecord | null>;
  requestAuditExport(
    authorization: AuditAuthorization,
    filters: AuditQueryFilters,
    idempotencyKey: string,
  ): Promise<AuditExportIntent>;
}

export const AUDIT_REPOSITORY = Symbol('AUDIT_REPOSITORY');
export const AUDIT_SERVICE = Symbol('AUDIT_SERVICE');

export function createSupportAuthorization(
  context: PlatformContext | SupportContext,
  reason: string,
): SupportAuthorization {
  return {
    context,
    reason,
  };
}
