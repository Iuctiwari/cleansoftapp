import { randomUUID } from 'node:crypto';
import { Injectable, type NestMiddleware } from '@nestjs/common';

import { PlatformError } from '../platform/platform.errors';
import { resolveHeaderValue, type RequestWithPlatformContext } from '../platform/platform.request';
import { AuthService } from './auth.service';

interface MiddlewareResponse {
  readonly locals?: Record<string, unknown>;
}

type NextFunction = () => void;

@Injectable()
export class AuthenticationContextMiddleware implements NestMiddleware {
  constructor(private readonly authService: AuthService) {}

  async use(
    request: RequestWithPlatformContext,
    _response: MiddlewareResponse,
    next: NextFunction,
  ): Promise<void> {
    const requestId = resolveHeaderValue(request.headers['x-request-id']) ?? randomUUID();
    const correlationId =
      request.correlationId ?? resolveHeaderValue(request.headers['x-correlation-id']) ?? requestId;
    request.correlationId = correlationId;

    const authorization = request.headers.authorization ?? request.headers.Authorization;
    const rawHeader = Array.isArray(authorization) ? authorization[0] : authorization;
    if (!rawHeader) {
      next();
      return;
    }

    if (!rawHeader.startsWith('Bearer ')) {
      throw new PlatformError({
        code: 'auth.authorization_header_invalid',
        category: 'unauthenticated',
        messageKey: 'errors.auth.authorization_header_invalid',
      });
    }

    const token = rawHeader.slice('Bearer '.length).trim();
    const resolution = await this.authService.authenticateAccessToken(token, {
      correlationId,
      causationId: requestId,
      requestId,
      ipAddress: resolveHeaderValue(request.headers['x-forwarded-for']) ?? undefined,
      userAgent: resolveHeaderValue(request.headers['user-agent']) ?? undefined,
    });
    request.trustedContext = resolution.principal.context;
    next();
  }
}
