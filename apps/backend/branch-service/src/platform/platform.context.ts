import type {
  PlatformContext,
  SupportContext,
  SupportAccessMode,
  TenantContext,
  TrustedContext,
} from './platform.types';
import { TRUSTED_CONTEXT_TOKEN } from './platform.types';

interface ContextSeed {
  readonly actorId: string;
  readonly actorType: 'user' | 'service' | 'support';
  readonly correlationId: string;
  readonly causationId: string;
  readonly requestId: string;
  readonly sessionId?: string;
}

export class TrustedContextFactory {
  createPlatformContext(
    seed: ContextSeed & {
      readonly roleCode?: string;
      readonly permissions?: readonly string[];
      readonly accessVersion?: number;
    },
  ): PlatformContext {
    return {
      kind: 'platform',
      actorId: seed.actorId,
      actorType: seed.actorType,
      correlationId: seed.correlationId,
      causationId: seed.causationId,
      requestId: seed.requestId,
      sessionId: seed.sessionId,
      roleCode: seed.roleCode,
      permissions: seed.permissions ? Object.freeze([...seed.permissions]) : undefined,
      accessVersion: seed.accessVersion,
      [TRUSTED_CONTEXT_TOKEN]: true,
    };
  }

  createTenantContext(
    seed: ContextSeed & {
      readonly tenantId: string;
      readonly branchId?: string;
      readonly permissions: readonly string[];
      readonly accessVersion: number;
      readonly roleCode?: string;
    },
  ): TenantContext {
    return {
      kind: 'tenant',
      actorId: seed.actorId,
      actorType: seed.actorType,
      correlationId: seed.correlationId,
      causationId: seed.causationId,
      requestId: seed.requestId,
      tenantId: seed.tenantId,
      branchId: seed.branchId,
      sessionId: seed.sessionId,
      permissions: Object.freeze([...seed.permissions]),
      accessVersion: seed.accessVersion,
      roleCode: seed.roleCode,
      [TRUSTED_CONTEXT_TOKEN]: true,
    };
  }

  createSupportContext(
    seed: ContextSeed & {
      readonly tenantId: string;
      readonly branchId?: string;
      readonly platformOperatorId: string;
      readonly reason: string;
      readonly supportAccessMode: SupportAccessMode;
    },
  ): SupportContext {
    return {
      kind: 'support',
      actorId: seed.actorId,
      actorType: 'support',
      correlationId: seed.correlationId,
      causationId: seed.causationId,
      requestId: seed.requestId,
      sessionId: seed.sessionId,
      tenantId: seed.tenantId,
      branchId: seed.branchId,
      platformOperatorId: seed.platformOperatorId,
      reason: seed.reason,
      supportAccessMode: seed.supportAccessMode,
      [TRUSTED_CONTEXT_TOKEN]: true,
    };
  }

  assertTrustedContext(context: TrustedContext): TrustedContext {
    if (context[TRUSTED_CONTEXT_TOKEN] !== true) {
      throw new Error('Untrusted context');
    }
    return context;
  }
}
