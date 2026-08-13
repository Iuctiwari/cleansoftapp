import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Types } from 'mongoose';

import type { CustomerScope } from './customer.types';

interface TrustedTenantContext {
  readonly actorId: string;
  readonly kind: 'tenant' | 'support';
  readonly tenantId: string;
  readonly branchId?: string;
}

export interface CustomerRequest {
  trustedContext?: TrustedTenantContext;
  customerScope?: CustomerScope;
}

@Injectable()
export class CustomerScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<CustomerRequest>();
    const trustedContext = request.trustedContext;

    if (!trustedContext) {
      throw new UnauthorizedException('Authenticated context is required');
    }

    if (
      !Types.ObjectId.isValid(trustedContext.actorId) ||
      !Types.ObjectId.isValid(trustedContext.tenantId) ||
      !trustedContext.branchId
    ) {
      throw new ForbiddenException('Tenant and branch scope are required');
    }

    request.customerScope = {
      actorId: trustedContext.actorId,
      tenantId: trustedContext.tenantId,
      branchId: trustedContext.branchId,
    };
    return true;
  }
}
