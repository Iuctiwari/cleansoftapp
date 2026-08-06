import { randomUUID } from 'node:crypto';
import { Injectable, type NestMiddleware } from '@nestjs/common';

import { PlatformError } from '../platform/platform.errors';
import type { RequestWithPlatformContext } from '../platform/platform.request';
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
    const requestId = this.resolveHeaderValue(request.headers['x-request-id']) ?? randomUUID();
    const correlationId =
      request.correlationId ??
      this.resolveHeaderValue(request.headers['x-correlation-id']) ??
      requestId;

    try {
      const resolution = await this.authService.authenticateAccessToken(token, {
        correlationId,
        causationId: requestId,
        requestId,
        ipAddress: this.resolveHeaderValue(request.headers['x-forwarded-for']) ?? undefined,
        userAgent: this.resolveHeaderValue(request.headers['user-agent']) ?? undefined,
      });
      request.trustedContext = resolution.principal.context;
      next();
    } catch (err) {
      throw err;
    }
  }

  private resolveHeaderValue(value: string | string[] | undefined): string | undefined {
    return Array.isArray(value) ? value[0] : value;
  }
}
