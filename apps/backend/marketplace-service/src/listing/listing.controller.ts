import { Body, Controller, Get, Param, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';

import {
  CATEGORY_LABELS,
  SHOP_CATEGORIES,
  type ConsumerPrincipal,
  type ShopCategory,
  type ShopPrincipal,
} from '../platform/marketplace.types';
import {
  assertCanEditListing,
  CurrentConsumer,
  CurrentShop,
} from '../platform/principal.decorators';
import { ShopDetailQueryDto, ShopSearchQueryDto, UpsertShopListingDto } from './listing.dto';
import {
  ListingService,
  type ShopDetail,
  type ShopListingView,
  type ShopSearchPage,
} from './listing.service';

/** Shop side: the branch's public listing (address, booking phone, hours…). */
@ApiTags('Shop listing')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'x-branch-id', required: false, description: 'Branch to manage' })
@Controller({ path: 'shop-listing', version: '1' })
export class ShopListingController {
  constructor(private readonly listingService: ListingService) {}

  @Get('me')
  @ApiOperation({
    summary: 'My branch listing, with missingFields to drive the "add your shop address" prompt',
  })
  get(@CurrentShop() shop: ShopPrincipal): Promise<ShopListingView> {
    return this.listingService.getForShop(shop);
  }

  @Put('me')
  @ApiOperation({ summary: 'Save my branch listing (owner or branch manager)' })
  save(
    @CurrentShop() shop: ShopPrincipal,
    @Body() body: UpsertShopListingDto,
  ): Promise<ShopListingView> {
    assertCanEditListing(shop);
    return this.listingService.saveForShop(shop, body);
  }
}

/** Customer side: browse shops. Login required, so phone numbers are never public. */
@ApiTags('Marketplace')
@ApiBearerAuth('access-token')
@Controller({ path: 'marketplace', version: '1' })
export class MarketplaceController {
  constructor(private readonly listingService: ListingService) {}

  @Get('categories')
  @ApiOperation({ summary: 'Service categories for the filter chips' })
  categories(): { code: ShopCategory; label: string }[] {
    return SHOP_CATEGORIES.map((code) => ({ code, label: CATEGORY_LABELS[code] }));
  }

  @Get('shops')
  @ApiOperation({ summary: 'Shops near my address (or GPS), nearest first' })
  search(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Query() query: ShopSearchQueryDto,
  ): Promise<ShopSearchPage> {
    return this.listingService.search(consumer, query);
  }

  @Get('shops/:shopId')
  @ApiOperation({ summary: 'One shop: address, hours, phone, services and distance' })
  detail(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Param('shopId') shopId: string,
    @Query() query: ShopDetailQueryDto,
  ): Promise<ShopDetail> {
    return this.listingService.detail(consumer, shopId, query);
  }
}
