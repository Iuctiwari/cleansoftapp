import { randomUUID } from 'node:crypto';

import { Injectable } from '@nestjs/common';

import { PlatformError } from '../platform/platform.errors';
import type { PaginatedResult } from '../platform/platform.types';
import type {
  AuditAuthorization,
  AuditExportIntent,
  AuditQueryFilters,
  AuditRecord,
  AuditRecordInput,
  AuditRecordOutcome,
  AuditRepository,
} from './audit.types';

function summarizeFields(
  summary: AuditRecordInput['newSummary'],
): Record<string, unknown> | undefined {
  return summary?.fields;
}

function ensureSummarySafety(summary?: Record<string, unknown>): void {
  if (!summary) {
    return;
  }

  for (const [key, value] of Object.entries(summary)) {
    const lowered = key.toLowerCase();
    if (
      lowered.includes('password') ||
      lowered.includes('token') ||
      lowered.includes('secret') ||
      lowered.includes('hash')
    ) {
      throw new PlatformError({
        code: 'audit.summary_forbidden',
        category: 'validation',
        messageKey: 'errors.audit.summary_forbidden',
      });
    }

    if (
      value !== null &&
      typeof value !== 'string' &&
      typeof value !== 'number' &&
      typeof value !== 'boolean'
    ) {
      throw new PlatformError({
        code: 'audit.summary_invalid',
        category: 'validation',
        messageKey: 'errors.audit.summary_invalid',
      });
    }
  }
}

function isVisibleToAuthorization(authorization: AuditAuthorization, record: AuditRecord): boolean {
  if (authorization.kind === 'platform') {
    return record.scopeKind === 'platform';
  }

  if (authorization.kind === 'tenant') {
    return record.tenantId === authorization.tenantId;
  }

  return record.tenantId === authorization.tenantId;
}

@Injectable()
export class InMemoryAuditRepository implements AuditRepository {
  private readonly records = new Map<string, AuditRecord>();
  private readonly recordsByObligation = new Map<string, AuditRecord>();
  private readonly exportIntents = new Map<string, AuditExportIntent>();

  record(record: AuditRecordInput): Promise<AuditRecordOutcome> {
    ensureSummarySafety(summarizeFields(record.oldSummary));
    ensureSummarySafety(summarizeFields(record.newSummary));

    const existing = this.recordsByObligation.get(record.sourceObligation);
    if (existing) {
      return Promise.resolve({
        auditId: existing.auditId,
        result: 'replayed',
      });
    }

    const auditId = randomUUID();
    const persisted: AuditRecord = {
      auditId,
      scopeKind: record.context.kind,
      tenantId: 'tenantId' in record.context ? record.context.tenantId : undefined,
      branchId: 'branchId' in record.context ? record.context.branchId : undefined,
      actor: record.actor,
      module: record.module,
      action: record.action,
      target: record.target,
      classification: record.classification,
      occurredAtUtc: new Date().toISOString(),
      correlationId: record.context.correlationId,
      causationId: record.context.causationId,
      requestId: record.context.requestId,
      result: 'committed',
      sourceObligation: record.sourceObligation,
      oldSummary: record.oldSummary,
      newSummary: record.newSummary,
      retentionTags: record.retentionTags,
      contractVersion: record.contractVersion,
    };

    this.records.set(auditId, persisted);
    this.recordsByObligation.set(record.sourceObligation, persisted);

    return Promise.resolve({
      auditId,
      result: 'committed',
    });
  }

  getById(auditId: string): Promise<AuditRecord | null> {
    return Promise.resolve(this.records.get(auditId) ?? null);
  }

  query(
    authorization: AuditAuthorization,
    filters: AuditQueryFilters,
    page: { page: number; pageSize: number },
  ): Promise<PaginatedResult<AuditRecord>> {
    const filtered = [...this.records.values()]
      .filter((record) => isVisibleToAuthorization(authorization, record))
      .filter((record) => (filters.module ? record.module === filters.module : true))
      .filter((record) => (filters.action ? record.action === filters.action : true))
      .filter((record) => (filters.actorId ? record.actor.actorId === filters.actorId : true))
      .filter((record) => (filters.targetId ? record.target.targetId === filters.targetId : true))
      .filter((record) =>
        filters.classification ? record.classification === filters.classification : true,
      )
      .filter((record) => (filters.tenantId ? record.tenantId === filters.tenantId : true))
      .sort((left, right) => right.occurredAtUtc.localeCompare(left.occurredAtUtc));

    const start = (page.page - 1) * page.pageSize;
    const items = filtered.slice(start, start + page.pageSize);

    return Promise.resolve({
      items,
      page: page.page,
      pageSize: page.pageSize,
      total: filtered.length,
    });
  }

  requestExport(
    authorization: AuditAuthorization,
    filters: AuditQueryFilters,
    idempotencyKey: string,
  ): Promise<AuditExportIntent> {
    const existing = this.exportIntents.get(idempotencyKey);
    if (existing) {
      return Promise.resolve(existing);
    }

    const intent: AuditExportIntent = {
      exportId: randomUUID(),
      requestedAtUtc: new Date().toISOString(),
      idempotencyKey,
      filters,
      authorizationKind: authorization.kind,
    };

    this.exportIntents.set(idempotencyKey, intent);
    return Promise.resolve(intent);
  }
}
