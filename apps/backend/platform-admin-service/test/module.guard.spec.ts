import { ExecutionContext, ForbiddenException, SetMetadata } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Reflector } from '@nestjs/core';

import { ModuleGuard } from '../src/module-access/module.guard';
import { ModuleKey } from '../src/module-access/module-key.enum';
import type {
  TenantModuleAccessRecord,
  TenantModuleAccessRepository,
} from '../src/module-access/module-access.types';
import { REQUIRE_MODULE_KEY } from '../src/module-access/require-module.decorator';

const TENANT_ID = '64f0c18f7c4d2f0012ab3400';

function buildRecord(overrides: Partial<TenantModuleAccessRecord> = {}): TenantModuleAccessRecord {
  return {
    id: '64f0c18f7c4d2f0012ab3999',
    tenantId: TENANT_ID,
    moduleKey: ModuleKey.PAYMENTS,
    isEnabled: true,
    updatedAt: new Date(),
    ...overrides,
  };
}

function buildContext(requiredModule: ModuleKey | undefined, tenantId?: string): ExecutionContext {
  class FakeHandler {}
  if (requiredModule) SetMetadata(REQUIRE_MODULE_KEY, requiredModule)(FakeHandler);

  const request = { method: 'POST', tenantId };

  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => FakeHandler,
    getClass: () => FakeHandler,
  } as unknown as ExecutionContext;
}

function buildConfigService(enforce: string): ConfigService {
  return { get: () => enforce } as unknown as ConfigService;
}

describe('ModuleGuard', () => {
  function buildGuard(
    repositoryOverrides: Partial<TenantModuleAccessRepository> = {},
    enforce = 'true',
  ): ModuleGuard {
    const repository: TenantModuleAccessRepository = {
      findAccess: jest.fn().mockResolvedValue(null),
      listForTenant: jest.fn().mockResolvedValue([]),
      setAccess: jest.fn(),
      ...repositoryOverrides,
    };
    return new ModuleGuard(repository, new Reflector(), buildConfigService(enforce));
  }

  it('allows a route with no @RequireModule metadata regardless of tenant', async () => {
    const guard = buildGuard();
    const context = buildContext(undefined, TENANT_ID);

    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  it('(b) allows a tenant with ZERO TenantModuleAccess records for any moduleKey (fail-open)', async () => {
    const findAccess = jest.fn().mockResolvedValue(null);
    const guard = buildGuard({ findAccess });

    const context = buildContext(ModuleKey.PAYMENTS, TENANT_ID);
    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(findAccess).toHaveBeenCalledWith(TENANT_ID, ModuleKey.PAYMENTS);
  });

  it('(d) blocks ONLY the specific module explicitly disabled for the tenant', async () => {
    const findAccess = jest.fn().mockImplementation((tenantId: string, moduleKey: ModuleKey) => {
      if (moduleKey === ModuleKey.PAYMENTS) {
        return Promise.resolve(buildRecord({ moduleKey: ModuleKey.PAYMENTS, isEnabled: false }));
      }
      return Promise.resolve(null); // no record for any other module
    });
    const guard = buildGuard({ findAccess });

    const paymentsContext = buildContext(ModuleKey.PAYMENTS, TENANT_ID);
    await expect(guard.canActivate(paymentsContext)).rejects.toBeInstanceOf(ForbiddenException);

    const orderManagementContext = buildContext(ModuleKey.ORDER_MANAGEMENT, TENANT_ID);
    await expect(guard.canActivate(orderManagementContext)).resolves.toBe(true);
  });

  it('allows the module when an explicit record has isEnabled: true', async () => {
    const guard = buildGuard({
      findAccess: jest.fn().mockResolvedValue(buildRecord({ isEnabled: true })),
    });
    const context = buildContext(ModuleKey.PAYMENTS, TENANT_ID);

    await expect(guard.canActivate(context)).resolves.toBe(true);
  });

  it('fails open when the request has no tenantId (host-wiring problem, not a tenant problem)', async () => {
    const findAccess = jest.fn();
    const guard = buildGuard({ findAccess });
    const context = buildContext(ModuleKey.PAYMENTS, undefined);

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(findAccess).not.toHaveBeenCalled();
  });

  describe('kill switch (ENFORCE_TENANT_GUARDS)', () => {
    it('with the flag OFF (default), allows a request for a module explicitly disabled, and never reads any data', async () => {
      const findAccess = jest
        .fn()
        .mockResolvedValue(buildRecord({ moduleKey: ModuleKey.PAYMENTS, isEnabled: false }));
      const guard = buildGuard({ findAccess }, 'false');

      const context = buildContext(ModuleKey.PAYMENTS, TENANT_ID);
      await expect(guard.canActivate(context)).resolves.toBe(true);
      expect(findAccess).not.toHaveBeenCalled();
    });

    it('with the flag OFF, behaves identically regardless of an unset (undefined) config value too', async () => {
      const guard = new ModuleGuard(
        {
          findAccess: jest
            .fn()
            .mockResolvedValue(buildRecord({ moduleKey: ModuleKey.PAYMENTS, isEnabled: false })),
          listForTenant: jest.fn(),
          setAccess: jest.fn(),
        },
        new Reflector(),
        { get: () => undefined } as unknown as ConfigService,
      );

      const context = buildContext(ModuleKey.PAYMENTS, TENANT_ID);
      await expect(guard.canActivate(context)).resolves.toBe(true);
    });

    it('with the flag ON, still enforces normally (regression check for the other tests in this file)', async () => {
      const guard = buildGuard(
        {
          findAccess: jest
            .fn()
            .mockResolvedValue(buildRecord({ moduleKey: ModuleKey.PAYMENTS, isEnabled: false })),
        },
        'true',
      );

      const context = buildContext(ModuleKey.PAYMENTS, TENANT_ID);
      await expect(guard.canActivate(context)).rejects.toBeInstanceOf(ForbiddenException);
    });
  });
});
