import { Injectable, UnauthorizedException, type NestMiddleware } from '@nestjs/common';

import { NotificationAuthResolver } from './notification-auth.resolver';
import type { NotificationRequest } from './notification.types';

type NextFunction = () => void;

@Injectable()
export class NotificationAuthenticationMiddleware implements NestMiddleware {
  constructor(private readonly authResolver: NotificationAuthResolver) {}

  async use(request: NotificationRequest, _response: unknown, next: NextFunction): Promise<void> {
    const authorization = this.header(request, 'authorization');
    if (!authorization) throw new UnauthorizedException('A valid bearer token is required');

    request.notificationScope = await this.authResolver.resolve(
      authorization,
      this.header(request, 'x-branch-id'),
    );
    next();
  }

  private header(request: NotificationRequest, name: string): string | undefined {
    const value = request.headers[name];
    return Array.isArray(value) ? value[0] : value;
  }
}
