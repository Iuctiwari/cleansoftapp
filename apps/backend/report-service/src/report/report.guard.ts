import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Types } from 'mongoose';

import type { ReportScope } from './report.types';

export interface ReportRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  reportScope?: ReportScope;
  trustedContext?: ReportScope;
}

@Injectable()
export class ReportScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<ReportRequest>();
    const trusted = request.trustedContext;
    if (!trusted) throw new UnauthorizedException('Authenticated context is required');
    if (
      !Types.ObjectId.isValid(trusted.actorId) ||
      !Types.ObjectId.isValid(trusted.tenantId) ||
      !trusted.branchId.trim()
    ) {
      throw new ForbiddenException('Valid tenant and branch scope is required');
    }
    request.reportScope = trusted;
    return true;
  }
}
