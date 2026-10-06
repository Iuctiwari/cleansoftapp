import { MiddlewareConsumer, Module, type NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';

import { AddressController } from './address/address.controller';
import { AddressService } from './address/address.service';
import { MarketplaceController, ShopListingController } from './listing/listing.controller';
import { ListingService } from './listing/listing.service';
import {
  ConsumerAuthenticationMiddleware,
  ShopAuthenticationMiddleware,
} from './platform/auth.middleware';
import { MarketplaceDatabase } from './platform/marketplace.database';
import { ShopServicesClient } from './platform/shop-services.client';
import { TenantDirectoryClient } from './platform/tenant-directory.client';
import { ConsumerRequestController, ShopRequestController } from './request/request.controller';
import { RequestService } from './request/request.service';

@Module({
  imports: [ConfigModule],
  controllers: [
    AddressController,
    MarketplaceController,
    ShopListingController,
    ConsumerRequestController,
    ShopRequestController,
  ],
  providers: [
    MarketplaceDatabase,
    TenantDirectoryClient,
    AddressService,
    ListingService,
    RequestService,
    ShopServicesClient,
    ConsumerAuthenticationMiddleware,
    ShopAuthenticationMiddleware,
  ],
})
export class MarketplaceModule implements NestModule {
  configure(consumer: MiddlewareConsumer): void {
    // Customer and shop routes are separate controllers, so a shop token can
    // never reach customer data and a customer token never reaches a listing editor.
    consumer
      .apply(ConsumerAuthenticationMiddleware)
      .forRoutes(AddressController, MarketplaceController, ConsumerRequestController);
    consumer
      .apply(ShopAuthenticationMiddleware)
      .forRoutes(ShopListingController, ShopRequestController);
  }
}
