import { ExecutionContext, ForbiddenException, SetMetadata } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';

import { createTenantEnforcementGuard } from '../src/tenant-enforcement.guard';
import { ModuleKey } from '../src/module-key.enum';
import { REQUIRE_MODULE_KEY } from '../src/require-module.decorator';
import type { TenantEnforcementResponse } from '../src/tenant-enforcement.types';

const TENANT_ID = '64f0c18f7c4d2f0012ab3400';

interface FakeRequest {
  readonly scope?: { readonly tenantId?: string };
}

function buildConfigService(values: Record<string, string | undefined>): ConfigService {
  return {
    get: (key: string, fallback?: string) => values[key] ?? fallback,
  } as unknown as ConfigService;
}

function buildContext(request: FakeRequest, requiredModule?: ModuleKey): ExecutionContext {
  class FakeHandler {}
  if (requiredModule) SetMetadata(REQUIRE_MODULE_KEY, requiredModule)(FakeHandler);

  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => FakeHandler,
    getClass: () => FakeHandler,
  } as unknown as ExecutionContext;
}

function mockFetchOnce(
  response: { ok: boolean; status?: number; json?: () => Promise<TenantEnforcementResponse> } | Error,
): jest.Mock {
  const mock =
    response instanceof Error
      ? jest.fn().mockRejectedValue(response)
      : jest.fn().mockResolvedValue(response);
  (global as unknown as { fetch: jest.Mock }).fetch = mock;
  return mock;
}

describe('createTenantEnforcementGuard', () => {
  const extractTenantId = (request: FakeRequest): string | undefined => request.scope?.tenantId;

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('kill switch OFF (default): allows the request and makes ZERO network calls', async () => {
    const fetchMock = mockFetchOnce({ ok: true, json: async () => ({ writeAllowed: false, disabledModuleKeys: [] }) });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({}), new Reflector());

    const context = buildContext({ scope: { tenantId: TENANT_ID } });
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('kill switch explicitly OFF: allows and makes zero network calls', async () => {
    const fetchMock = mockFetchOnce({ ok: true, json: async () => ({ writeAllowed: false, disabledModuleKeys: [] }) });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'false' }), new Reflector());

    await expect(
      guard.canActivate(buildContext({ scope: { tenantId: TENANT_ID } })),
    ).resolves.toBe(true);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('kill switch ON, no tenantId extractable from the request: fails open, zero network calls', async () => {
    const fetchMock = mockFetchOnce({ ok: true, json: async () => ({ writeAllowed: false, disabledModuleKeys: [] }) });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'true' }), new Reflector());

    await expect(guard.canActivate(buildContext({ scope: undefined }))).resolves.toBe(true);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('kill switch ON, platform-admin-service allows the write: passes through', async () => {
    mockFetchOnce({ ok: true, json: async () => ({ writeAllowed: true, disabledModuleKeys: [] }) });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'true' }), new Reflector());

    await expect(
      guard.canActivate(buildContext({ scope: { tenantId: TENANT_ID } })),
    ).resolves.toBe(true);
  });

  it('kill switch ON, platform-admin-service blocks the write: throws ForbiddenException', async () => {
    mockFetchOnce({
      ok: true,
      json: async () => ({ writeAllowed: false, blockedReason: 'Subscription SUSPENDED', disabledModuleKeys: [] }),
    });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'true' }), new Reflector());

    await expect(
      guard.canActivate(buildContext({ scope: { tenantId: TENANT_ID } })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('kill switch ON, write allowed but required module is disabled: throws ForbiddenException', async () => {
    mockFetchOnce({
      ok: true,
      json: async () => ({ writeAllowed: true, disabledModuleKeys: [ModuleKey.PAYMENTS] }),
    });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'true' }), new Reflector());

    await expect(
      guard.canActivate(buildContext({ scope: { tenantId: TENANT_ID } }, ModuleKey.PAYMENTS)),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('kill switch ON, required module NOT in disabledModuleKeys: passes through', async () => {
    mockFetchOnce({
      ok: true,
      json: async () => ({ writeAllowed: true, disabledModuleKeys: [ModuleKey.PAYMENTS] }),
    });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'true' }), new Reflector());

    await expect(
      guard.canActivate(buildContext({ scope: { tenantId: TENANT_ID } }, ModuleKey.ORDER_MANAGEMENT)),
    ).resolves.toBe(true);
  });

  it('no @RequireModule metadata: module check is skipped even if disabledModuleKeys is non-empty', async () => {
    mockFetchOnce({
      ok: true,
      json: async () => ({ writeAllowed: true, disabledModuleKeys: [ModuleKey.PAYMENTS, ModuleKey.EXPENSES] }),
    });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'true' }), new Reflector());

    await expect(
      guard.canActivate(buildContext({ scope: { tenantId: TENANT_ID } })),
    ).resolves.toBe(true);
  });

  it('kill switch ON, platform-admin-service returns a non-2xx response: fails open', async () => {
    mockFetchOnce({ ok: false, status: 500 });
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'true' }), new Reflector());

    await expect(
      guard.canActivate(buildContext({ scope: { tenantId: TENANT_ID } })),
    ).resolves.toBe(true);
  });

  it('kill switch ON, network error/timeout reaching platform-admin-service: fails open', async () => {
    mockFetchOnce(new Error('ECONNREFUSED'));
    const Guard = createTenantEnforcementGuard<FakeRequest>(extractTenantId);
    const guard = new Guard(buildConfigService({ ENFORCE_TENANT_GUARDS: 'true' }), new Reflector());

    await expect(
      guard.canActivate(buildContext({ scope: { tenantId: TENANT_ID } })),
    ).resolves.toBe(true);
  });
});
