import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Types } from 'mongoose';

import type { SettingsScope } from './settings.types';

export interface SettingsRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  trustedContext?: SettingsScope;
  settingsScope?: SettingsScope;
}

@Injectable()
export class SettingsScopeGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<SettingsRequest>();
    const trusted = request.trustedContext;
    if (!trusted) throw new UnauthorizedException('Authenticated context is required');
    if (!Types.ObjectId.isValid(trusted.actorId) || !Types.ObjectId.isValid(trusted.tenantId)) {
      throw new ForbiddenException('Valid tenant scope is required');
    }
    request.settingsScope = trusted;
    return true;
  }
}
