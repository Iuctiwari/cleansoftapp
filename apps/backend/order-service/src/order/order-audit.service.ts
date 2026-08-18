import { Injectable, Logger } from '@nestjs/common';

import type { OrderScope } from './order.types';

@Injectable()
export class OrderAuditService {
  private readonly logger = new Logger('OrderAudit');

  record(
    scope: OrderScope,
    action: string,
    orderId: string,
    changes?: Record<string, unknown>,
  ): void {
    this.logger.log(
      JSON.stringify({
        action,
        actorId: scope.actorId,
        branchId: scope.branchId,
        changes,
        module: 'orders',
        orderId,
        tenantId: scope.tenantId,
        timestamp: new Date().toISOString(),
      }),
    );
  }
}
