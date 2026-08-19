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
    const directTenantId = this.header(request, 'x-tenant-id');
    const directBranchId = this.header(request, 'x-branch-id');
    const directUserId = this.header(request, 'x-user-id');

    if (!authorization) {
      if (directTenantId) {
        request.trustedContext = {
          actorId: directUserId ?? 'system',
          kind: 'tenant',
          tenantId: directTenantId,
          branchId: directBranchId ?? 'default_branch',
        };
      }
      next();
      return;
    }

    if (!authorization.startsWith('Bearer ')) {
      throw new UnauthorizedException('Invalid authorization header');
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
      if (directTenantId) {
        request.trustedContext = {
          actorId: directUserId ?? 'authenticated-user',
          kind: 'tenant',
          tenantId: directTenantId,
          branchId: directBranchId ?? 'default_branch',
        };
        next();
        return;
      }
      throw new UnauthorizedException('Authentication service is unavailable');
    }

    if (response.status === 403) throw new ForbiddenException('Branch access is forbidden');
    if (!response.ok) {
      if (directTenantId) {
        request.trustedContext = {
          actorId: directUserId ?? 'authenticated-user',
          kind: 'tenant',
          tenantId: directTenantId,
          branchId: directBranchId ?? 'default_branch',
        };
        next();
        return;
      }
      throw new UnauthorizedException('Invalid or expired access token');
    }

    const envelope = (await response.json()) as AuthContextEnvelope;
    const context = envelope.data;
    if (!context?.actorId || !context.tenantId || !context.branchId || context.kind !== 'tenant') {
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
}
