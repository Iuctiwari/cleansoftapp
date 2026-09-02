import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Types } from 'mongoose';

import type { ExpenseScope } from './expense.types';

export interface ExpenseTrustedContext {
  readonly actorId: string;
  readonly kind: 'tenant';
  readonly tenantId: string;
  readonly branchId: string;
  readonly roleCode: string;
  readonly permissions: readonly string[];
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

    if (!trustedContext) {
      throw new UnauthorizedException('Authenticated context is required');
    }

    if (trustedContext.kind !== 'tenant') {
      throw new ForbiddenException('Tenant context is required');
    }

    if (
      !Types.ObjectId.isValid(trustedContext.actorId) ||
      !Types.ObjectId.isValid(trustedContext.tenantId) ||
      !trustedContext.branchId.trim()
    ) {
      throw new ForbiddenException('Valid tenant and branch scope is required');
    }

    request.expenseScope = {
      actorId: trustedContext.actorId,
      tenantId: trustedContext.tenantId,
      branchId: trustedContext.branchId,
      roleCode: trustedContext.roleCode,
      permissions: trustedContext.permissions,
    };
    return true;
  }
}
