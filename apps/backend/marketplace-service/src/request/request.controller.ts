import { Body, Controller, Get, HttpCode, Param, Post, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';

import type { ConsumerPrincipal, ShopPrincipal } from '../platform/marketplace.types';
import { CurrentConsumer, CurrentShop } from '../platform/principal.decorators';
import {
  AcceptRequestDto,
  CancelRequestDto,
  CompleteRequestDto,
  CreateServiceRequestDto,
  DeclineRequestDto,
  LinkOrderDto,
  ListRequestsQueryDto,
} from './request.dto';
import {
  RequestService,
  type CustomerRequestView,
  type PageOf,
  type ShopRequestSummary,
  type ShopRequestView,
} from './request.service';

/** Customer side: send and track requests to shops. */
@ApiTags('Customer requests')
@ApiBearerAuth('access-token')
@Controller({ path: 'consumer/requests', version: '1' })
export class ConsumerRequestController {
  constructor(private readonly requestService: RequestService) {}

  @Post()
  @ApiOperation({ summary: 'Send a request / appointment to a shop' })
  create(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Body() body: CreateServiceRequestDto,
  ): Promise<CustomerRequestView> {
    return this.requestService.create(consumer, body);
  }

  @Get()
  @ApiOperation({ summary: 'My requests, newest first' })
  list(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Query() query: ListRequestsQueryDto,
  ): Promise<PageOf<CustomerRequestView>> {
    return this.requestService.listForCustomer(consumer, query);
  }

  @Get(':requestId')
  @ApiOperation({ summary: 'One of my requests, with its status history' })
  get(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Param('requestId') requestId: string,
  ): Promise<CustomerRequestView> {
    return this.requestService.getForCustomer(consumer, requestId);
  }

  @Post(':requestId/cancel')
  @HttpCode(200)
  @ApiOperation({ summary: 'Cancel my request (until the shop has created the order)' })
  cancel(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Param('requestId') requestId: string,
    @Body() body: CancelRequestDto,
  ): Promise<CustomerRequestView> {
    return this.requestService.cancel(consumer, requestId, body);
  }
}

/** Shop side: the "Online Requests" module for the signed-in branch. */
@ApiTags('Online requests (shop)')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'x-branch-id', required: false, description: 'Branch to manage' })
@Controller({ path: 'shop/requests', version: '1' })
export class ShopRequestController {
  constructor(private readonly requestService: RequestService) {}

  @Get()
  @ApiOperation({ summary: 'Requests to this branch, newest first (filter by status)' })
  list(
    @CurrentShop() shop: ShopPrincipal,
    @Query() query: ListRequestsQueryDto,
  ): Promise<PageOf<ShopRequestView>> {
    return this.requestService.listForShop(shop, query);
  }

  @Get('summary')
  @ApiOperation({ summary: 'Counts by status — "pending" drives the tab badge' })
  summary(@CurrentShop() shop: ShopPrincipal): Promise<ShopRequestSummary> {
    return this.requestService.summaryForShop(shop);
  }

  @Get(':requestId')
  @ApiOperation({ summary: 'One request with customer details and allowed actions' })
  get(
    @CurrentShop() shop: ShopPrincipal,
    @Param('requestId') requestId: string,
  ): Promise<ShopRequestView> {
    return this.requestService.getForShop(shop, requestId);
  }

  @Post(':requestId/accept')
  @HttpCode(200)
  @ApiOperation({ summary: 'Accept, optionally with a confirmed time and a note' })
  accept(
    @CurrentShop() shop: ShopPrincipal,
    @Param('requestId') requestId: string,
    @Body() body: AcceptRequestDto,
  ): Promise<ShopRequestView> {
    return this.requestService.accept(shop, requestId, body);
  }

  @Post(':requestId/decline')
  @HttpCode(200)
  @ApiOperation({ summary: 'Decline with a reason shown to the customer' })
  decline(
    @CurrentShop() shop: ShopPrincipal,
    @Param('requestId') requestId: string,
    @Body() body: DeclineRequestDto,
  ): Promise<ShopRequestView> {
    return this.requestService.decline(shop, requestId, body);
  }

  @Post(':requestId/link-order')
  @HttpCode(200)
  @ApiOperation({ summary: 'Link the order created for this accepted request' })
  linkOrder(
    @CurrentShop() shop: ShopPrincipal,
    @Param('requestId') requestId: string,
    @Body() body: LinkOrderDto,
  ): Promise<ShopRequestView> {
    return this.requestService.linkOrder(shop, requestId, body);
  }

  @Post(':requestId/complete')
  @HttpCode(200)
  @ApiOperation({ summary: 'Mark the request done' })
  complete(
    @CurrentShop() shop: ShopPrincipal,
    @Param('requestId') requestId: string,
    @Body() body: CompleteRequestDto,
  ): Promise<ShopRequestView> {
    return this.requestService.complete(shop, requestId, body);
  }
}
