import { Controller, Headers, HttpCode, Post, UnauthorizedException } from '@nestjs/common';
import { ApiExcludeController } from '@nestjs/swagger';

import { type OverdueAlertResult, OrderOverdueService } from './order-overdue.service';

/** Service-to-service only: the server's daily cron calls this. */
@ApiExcludeController()
@Controller({ path: 'internal/overdue-alerts', version: '1' })
export class OrderOverdueController {
  constructor(private readonly overdue: OrderOverdueService) {}

  @Post()
  @HttpCode(200)
  run(@Headers('x-internal-secret') secret?: string): Promise<OverdueAlertResult> {
    if (!this.overdue.isAuthorised(secret)) {
      throw new UnauthorizedException('A valid internal service secret is required');
    }
    return this.overdue.alertOwners();
  }
}
