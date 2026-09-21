import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { InternalServiceGuard } from '../src/enforcement/internal-service.guard';

function buildConfigService(secret: string | undefined): ConfigService {
  return { get: () => secret } as unknown as ConfigService;
}

function buildContext(headerValue: string | undefined): ExecutionContext {
  const request = { headers: headerValue ? { 'x-enforcement-key': headerValue } : {} };
  return {
    switchToHttp: () => ({ getRequest: () => request }),
  } as unknown as ExecutionContext;
}

describe('InternalServiceGuard', () => {
  it('allows a request with the correct shared secret', () => {
    const guard = new InternalServiceGuard(buildConfigService('correct-secret-value'));
    expect(guard.canActivate(buildContext('correct-secret-value'))).toBe(true);
  });

  it('rejects a request with the wrong secret', () => {
    const guard = new InternalServiceGuard(buildConfigService('correct-secret-value'));
    expect(() => guard.canActivate(buildContext('wrong-secret'))).toThrow(UnauthorizedException);
  });

  it('rejects a request with no header at all', () => {
    const guard = new InternalServiceGuard(buildConfigService('correct-secret-value'));
    expect(() => guard.canActivate(buildContext(undefined))).toThrow(UnauthorizedException);
  });

  it('fails CLOSED (rejects) when the secret is not configured on this service at all', () => {
    const guard = new InternalServiceGuard(buildConfigService(undefined));
    expect(() => guard.canActivate(buildContext('anything'))).toThrow(UnauthorizedException);
  });
});
