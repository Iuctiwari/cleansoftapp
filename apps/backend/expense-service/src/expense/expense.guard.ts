import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import type { ExpenseScope } from './expense.types';

export interface ExpenseTrustedContext {
  readonly actorId: string;
  readonly kind: 'tenant';
  readonly tenantId: string;
  readonly branchId: string;
}

export interface ExpenseRequest {
  trustedContext?: ExpenseTrustedContext;
  expenseScope?: ExpenseScope;
  headers: Record<string, string | string[] | undefined>;
  query: Record<string, string | undefined>;
}

@Injectable()
export class ExpenseScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<ExpenseRequest>();
    const trustedContext = request.trustedContext;

    if (trustedContext) {
      if (trustedContext.kind !== 'tenant') {
        throw new ForbiddenException('Tenant context is required');
      }
      request.expenseScope = {
        actorId: trustedContext.actorId,
        tenantId: trustedContext.tenantId,
        branchId: trustedContext.branchId,
      };
      return true;
    }

    const tenantHeader = this.header(request, 'x-tenant-id');
    const branchHeader = this.header(request, 'x-branch-id') || request.query.branchId;
    const actorHeader = this.header(request, 'x-user-id');

    if (tenantHeader) {
      request.expenseScope = {
        actorId: actorHeader || 'system',
        tenantId: tenantHeader,
        branchId: branchHeader || 'default_branch',
      };
      return true;
    }

    throw new UnauthorizedException('Authentication is required');
  }

  private header(request: ExpenseRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }
}
