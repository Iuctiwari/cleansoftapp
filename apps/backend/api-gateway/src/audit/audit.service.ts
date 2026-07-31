import { Inject, Injectable } from '@nestjs/common';

import { PlatformError } from '../platform/platform.errors';
import type { PaginatedResult } from '../platform/platform.types';
import {
  AUDIT_REPOSITORY,
  type AuditAuthorization,
  type AuditExportIntent,
  type AuditQueryFilters,
  type AuditRecord,
  type AuditRecordInput,
  type AuditRecordOutcome,
  type AuditRepository,
  type AuditServiceContract,
} from './audit.types';

@Injectable()
export class AuditService implements AuditServiceContract {
  constructor(@Inject(AUDIT_REPOSITORY) private readonly auditRepository: AuditRepository) {}

  async recordAudit(obligation: AuditRecordInput): Promise<AuditRecordOutcome> {
    return this.auditRepository.record(obligation);
  }

  async queryAudit(
    authorization: AuditAuthorization,
    filters: AuditQueryFilters,
    page: { page: number; pageSize: number },
  ): Promise<PaginatedResult<AuditRecord>> {
    return this.auditRepository.query(authorization, filters, page);
  }

  async getAuditById(
    authorization: AuditAuthorization,
    auditId: string,
  ): Promise<AuditRecord | null> {
    const record = await this.auditRepository.getById(auditId);
    if (!record) {
      return null;
    }

    if (authorization.kind === 'platform' && record.scopeKind !== 'platform') {
      throw new PlatformError({
        code: 'audit.out_of_scope',
        category: 'not_found',
        messageKey: 'errors.audit.not_found',
      });
    }

    if (authorization.kind !== 'platform' && record.tenantId !== authorization.tenantId) {
      throw new PlatformError({
        code: 'audit.out_of_scope',
        category: 'not_found',
        messageKey: 'errors.audit.not_found',
      });
    }

    return record;
  }

  async requestAuditExport(
    authorization: AuditAuthorization,
    filters: AuditQueryFilters,
    idempotencyKey: string,
  ): Promise<AuditExportIntent> {
    if (idempotencyKey.trim().length === 0) {
      throw new PlatformError({
        code: 'audit.export_idempotency_required',
        category: 'validation',
        messageKey: 'errors.audit.export_idempotency_required',
      });
    }

    return this.auditRepository.requestExport(authorization, filters, idempotencyKey);
  }
}
