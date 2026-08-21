import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { ExpenseRequest } from './expense.guard';

interface ExpenseAuthenticationRequest extends ExpenseRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
}

interface AuthContextEnvelope {
  readonly data?: {
    readonly actorId?: string;
    readonly kind?: 'tenant';
    readonly tenantId?: string;
    readonly branchId?: string;
  };
}

interface AccessTokenEnvelope {
  readonly claims?: {
    readonly userId?: string;
    readonly tenantId?: string;
    readonly roleCode?: string;
    readonly permissions?: readonly string[];
  };
}

type NextFunction = () => void;

@Injectable()
export class ExpenseAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  async use(
    request: ExpenseAuthenticationRequest,
    _response: unknown,
    next: NextFunction,
  ): Promise<void> {
    const authorization = this.header(request, 'authorization');
    const directBranchId = this.header(request, 'x-branch-id');

    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('A valid bearer token is required');
    }

    const authBaseUrl = this.configService.get<string>(
      'AUTH_SERVICE_BASE_URL',
      'http://localhost:3001/api',
    );

    let response: Response;
    try {
      response = await fetch(`${authBaseUrl.replace(/\/$/, '')}/v1/auth/context`, {
        headers: {
          authorization,
          ...(directBranchId ? { 'x-branch-id': directBranchId } : {}),
        },
      });
    } catch {
      throw new UnauthorizedException('Authentication service is unavailable');
    }

    if (response.status === 403) throw new ForbiddenException('Branch access is forbidden');
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');

    const envelope = (await response.json()) as AuthContextEnvelope;
    const context = envelope.data;
    const claims = this.readClaims(authorization.slice('Bearer '.length));
    if (
      context?.kind !== 'tenant' ||
      !context.actorId ||
      !context.tenantId ||
      !context.branchId ||
      claims.userId !== context.actorId ||
      claims.tenantId !== context.tenantId ||
      !claims.roleCode
    ) {
      throw new UnauthorizedException('Invalid authenticated context');
    }

    request.trustedContext = {
      actorId: context.actorId,
      kind: context.kind,
      tenantId: context.tenantId,
      branchId: context.branchId,
    };
    next();
  }

  private header(request: ExpenseAuthenticationRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }

  private readClaims(token: string): NonNullable<AccessTokenEnvelope['claims']> {
    const payload = token.split('.')[1];
    try {
      const envelope = JSON.parse(
        Buffer.from(payload, 'base64url').toString('utf8'),
      ) as AccessTokenEnvelope;
      if (envelope.claims) return envelope.claims;
    } catch {
      // The token was validated by auth-service, but its local representation is unusable.
    }
    throw new UnauthorizedException('Invalid access token claims');
  }
}
