import { TrustedContextFactory } from '../src/platform/platform.context';

describe('TrustedContextFactory', () => {
  const factory = new TrustedContextFactory();

  it('creates a trusted tenant context that cannot be confused with platform scope', () => {
    const context = factory.createTenantContext({
      actorId: 'user-1',
      actorType: 'user',
      correlationId: 'corr-1',
      causationId: 'cause-1',
      requestId: 'req-1',
      tenantId: 'tenant-1',
      branchId: 'branch-1',
      permissions: ['audit:read'],
      accessVersion: 4,
    });

    expect(context.kind).toBe('tenant');
    expect(context.tenantId).toBe('tenant-1');
    expect(context.permissions).toEqual(['audit:read']);
  });
});
