import { AuditService } from '../src/audit/audit.service';
import { InMemoryAuditRepository } from '../src/audit/audit.repository';
import { TrustedContextFactory } from '../src/platform/platform.context';

describe('AuditService', () => {
  const trustedContextFactory = new TrustedContextFactory();

  it('deduplicates by source obligation and returns a replay outcome', async () => {
    const repository = new InMemoryAuditRepository();
    const service = new AuditService(repository);
    const context = trustedContextFactory.createTenantContext({
      actorId: 'user-1',
      actorType: 'user',
      correlationId: 'corr-1',
      causationId: 'cause-1',
      requestId: 'req-1',
      tenantId: 'tenant-1',
      permissions: ['audit:write'],
      accessVersion: 1,
    });

    const first = await service.recordAudit({
      sourceObligation: 'payment:123',
      idempotencyKey: 'payment:123',
      module: 'payments',
      action: 'recorded',
      classification: 'financial',
      actor: { actorId: 'user-1', actorType: 'user' },
      target: { targetId: 'payment-1', targetType: 'payment' },
      context,
      retentionTags: [{ code: 'fin', label: 'Financial' }],
      contractVersion: { major: 1, minor: 0 },
    });

    const second = await service.recordAudit({
      sourceObligation: 'payment:123',
      idempotencyKey: 'payment:123',
      module: 'payments',
      action: 'recorded',
      classification: 'financial',
      actor: { actorId: 'user-1', actorType: 'user' },
      target: { targetId: 'payment-1', targetType: 'payment' },
      context,
      retentionTags: [{ code: 'fin', label: 'Financial' }],
      contractVersion: { major: 1, minor: 0 },
    });

    expect(first.result).toBe('committed');
    expect(second.result).toBe('replayed');
    expect(second.auditId).toBe(first.auditId);
  });
});
