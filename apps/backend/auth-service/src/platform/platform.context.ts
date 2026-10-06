import { PlatformError } from './platform.errors';
import type {
  ConsumerContext,
  PlatformContext,
  SupportContext,
  SupportAccessMode,
  StaffTrustedContext,
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

  createConsumerContext(seed: ContextSeed & { readonly accessVersion: number }): ConsumerContext {
    return {
      kind: 'consumer',
      actorId: seed.actorId,
      actorType: 'user',
      correlationId: seed.correlationId,
      causationId: seed.causationId,
      requestId: seed.requestId,
      sessionId: seed.sessionId,
      accessVersion: seed.accessVersion,
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

  /** Rejects marketplace consumer sessions on staff-only (platform/tenant/support) endpoints. */
  assertStaffContext(context: TrustedContext): StaffTrustedContext {
    const trusted = this.assertTrustedContext(context);
    if (trusted.kind === 'consumer') {
      throw new PlatformError({
        code: 'auth.staff_context_required',
        category: 'forbidden',
        messageKey: 'errors.auth.staff_context_required',
      });
    }
    return trusted;
  }
}
