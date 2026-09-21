import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { SubscriptionModule } from '../subscription/subscription.module';
import { HttpTenantStatusLookup } from './http-tenant-status.lookup';
import { TenantStatusGuard } from './tenant-status.guard';
import { TENANT_STATUS_LOOKUP } from './tenant-status.types';

/**
 * TenantStatusGuard itself still isn't wired onto any route in THIS service
 * (Phase 6 wires it onto OTHER services' routes via the internal enforcement
 * endpoint instead — see ../enforcement/). TENANT_STATUS_LOOKUP is exported
 * so EnforcementModule can reuse the exact same cross-service lookup this
 * guard uses, rather than re-registering a second instance of it.
 */
@Module({
  imports: [ConfigModule, SubscriptionModule],
  providers: [
    TenantStatusGuard,
    HttpTenantStatusLookup,
    { provide: TENANT_STATUS_LOOKUP, useExisting: HttpTenantStatusLookup },
  ],
  exports: [TenantStatusGuard, TENANT_STATUS_LOOKUP],
})
export class TenantStatusModule {}
