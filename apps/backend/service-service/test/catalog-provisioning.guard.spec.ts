import { UnauthorizedException, type ExecutionContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { CatalogProvisioningGuard } from '../src/catalog/catalog-provisioning.guard';

function context(key?: string): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({ headers: key ? { 'x-catalog-provisioning-key': key } : {} }),
    }),
  } as unknown as ExecutionContext;
}

describe('CatalogProvisioningGuard', () => {
  const guard = new CatalogProvisioningGuard(
    new ConfigService({ CATALOG_PROVISIONING_KEY: 'trusted-internal-key' }),
  );

  it('accepts the configured internal credential', () => {
    expect(guard.canActivate(context('trusted-internal-key'))).toBe(true);
  });

  it.each([undefined, 'wrong-key'])('rejects absent or untrusted credentials', (key) => {
    expect(() => guard.canActivate(context(key))).toThrow(UnauthorizedException);
  });
});
