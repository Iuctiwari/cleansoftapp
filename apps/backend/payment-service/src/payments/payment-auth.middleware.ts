import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { PaymentRequest } from './payment.types';

type NextFunction = () => void;

@Injectable()
export class PaymentAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly config: ConfigService) {}

  async use(request: PaymentRequest, _response: unknown, next: NextFunction): Promise<void> {
    const authorization = this.header(request, 'authorization');
    const branchHeader = this.header(request, 'x-branch-id');
    if (!authorization?.startsWith('Bearer ') || !branchHeader) {
      throw new UnauthorizedException('A valid bearer token and branch are required');
    }
    let response: Response;
    try {
      response = await fetch(
        `${this.config.get<string>('AUTH_SERVICE_BASE_URL', 'http://localhost:3000/api').replace(/\/$/, '')}/v1/auth/context`,
        { headers: { authorization, 'x-branch-id': branchHeader } },
      );
    } catch {
      throw new UnauthorizedException('Authentication service is unavailable');
    }
    if (response.status === 403) throw new ForbiddenException('Branch access is forbidden');
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');
    const payload = (await response.json()) as {
      data?: { actorId?: string; branchId?: string; kind?: string; tenantId?: string };
    };
    const context = payload.data;
    const claims = this.claims(authorization.slice('Bearer '.length));
    if (
      context?.kind !== 'tenant' ||
      !context.actorId ||
      !context.tenantId ||
      !context.branchId ||
      context.actorId !== claims.userId ||
      context.tenantId !== claims.tenantId ||
      !claims.roleCode
    ) {
      throw new UnauthorizedException('Invalid authenticated context');
    }
    request.paymentScope = {
      actorId: context.actorId,
      authorization,
      branchId: context.branchId,
      permissions: Object.freeze([...(claims.permissions ?? [])]),
      roleCode: claims.roleCode,
      tenantId: context.tenantId,
    };
    next();
  }

  private header(request: PaymentRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private claims(token: string): {
    userId?: string;
    tenantId?: string;
    roleCode?: string;
    permissions?: readonly string[];
  } {
    try {
      const payload = token.split('.')[1];
      const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as {
        claims?: ReturnType<PaymentAuthenticationMiddleware['claims']>;
      };
      if (decoded.claims) return decoded.claims;
    } catch {
      // Auth Service validated the token; reject unusable local claims below.
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
