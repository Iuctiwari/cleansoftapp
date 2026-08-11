import { AuthenticationContextMiddleware } from '../src/auth/auth.middleware';
import type { AuthService } from '../src/auth/auth.service';
import type { RequestWithPlatformContext } from '../src/platform/platform.request';
import { TRUSTED_CONTEXT_TOKEN, type TenantContext } from '../src/platform/platform.types';

describe('AuthenticationContextMiddleware', () => {
  it('resolves a bearer token and attaches trusted tenant context', async () => {
    const context: TenantContext = {
      kind: 'tenant',
      tenantId: 'tenant-1',
      actorId: 'owner-1',
      actorType: 'user',
      permissions: ['tenant.read'],
      accessVersion: 1,
      correlationId: 'correlation-1',
      causationId: 'request-1',
      requestId: 'request-1',
      [TRUSTED_CONTEXT_TOKEN]: true,
    };
    const authenticateAccessToken = jest.fn().mockResolvedValue({
      principal: { context },
    });
    const middleware = new AuthenticationContextMiddleware({
      authenticateAccessToken,
    } as unknown as AuthService);
    const request = {
      headers: {
        authorization: 'Bearer valid-token',
        'x-correlation-id': 'correlation-1',
        'x-request-id': 'request-1',
      },
    } as RequestWithPlatformContext;
    const next = jest.fn();

    await middleware.use(request, {}, next);

    expect(authenticateAccessToken).toHaveBeenCalledWith(
      'valid-token',
      expect.objectContaining({ correlationId: 'correlation-1', requestId: 'request-1' }),
    );
    expect(request.trustedContext).toBe(context);
    expect(request.correlationId).toBe('correlation-1');
    expect(next).toHaveBeenCalledTimes(1);
  });

  it('leaves public requests without an Authorization header unauthenticated', async () => {
    const authenticateAccessToken = jest.fn();
    const middleware = new AuthenticationContextMiddleware({
      authenticateAccessToken,
    } as unknown as AuthService);
    const request = { headers: {} } as RequestWithPlatformContext;
    const next = jest.fn();

    await middleware.use(request, {}, next);

    expect(authenticateAccessToken).not.toHaveBeenCalled();
    expect(request.trustedContext).toBeUndefined();
    expect(request.correlationId).toBeDefined();
    expect(next).toHaveBeenCalledTimes(1);
  });
});
