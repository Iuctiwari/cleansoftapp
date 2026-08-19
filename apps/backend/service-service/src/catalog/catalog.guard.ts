import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Types } from 'mongoose';

import type { CatalogScope } from './catalog.types';

export interface CatalogRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  trustedContext?: CatalogScope;
  catalogScope?: CatalogScope;
}

@Injectable()
export class CatalogScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<CatalogRequest>();
    const trusted = request.trustedContext;
    if (!trusted) throw new UnauthorizedException('Authenticated context is required');
    if (
      !Types.ObjectId.isValid(trusted.actorId) ||
      !Types.ObjectId.isValid(trusted.tenantId) ||
      !trusted.branchId.trim()
    ) {
      throw new ForbiddenException('Valid tenant and branch scope is required');
    }
    request.catalogScope = trusted;
    return true;
  }
}
