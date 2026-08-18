import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Types } from 'mongoose';

import type { OrderScope } from './order.types';

export interface OrderRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  trustedContext?: OrderScope;
  orderScope?: OrderScope;
}

@Injectable()
export class OrderScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<OrderRequest>();
    const trusted = request.trustedContext;
    if (!trusted) throw new UnauthorizedException('Authenticated context is required');
    if (
      !Types.ObjectId.isValid(trusted.actorId) ||
      !Types.ObjectId.isValid(trusted.tenantId) ||
      !trusted.branchId.trim()
    ) {
      throw new ForbiddenException('Valid tenant and branch scope is required');
    }
    request.orderScope = trusted;
    return true;
  }
}
