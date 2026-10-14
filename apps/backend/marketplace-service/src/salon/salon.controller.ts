import { Body, Controller, Get, Param, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiHeader, ApiOperation, ApiTags } from '@nestjs/swagger';

import type { ShopPrincipal } from '../platform/marketplace.types';
import { CurrentShop } from '../platform/principal.decorators';
import {
  AssignSalonStaffDto,
  SalonWalkInDto,
  SaveSalonConfigDto,
  SalonScheduleQueryDto,
  SalonSlotsQueryDto,
} from './salon.dto';
import {
  SalonService,
  type SalonConfigView,
  type SalonMenuView,
  type SalonScheduleView,
  type SalonSlotsView,
} from './salon.service';

/** Shop side: a salon's online-booking setup and its day diary. */
@ApiTags('Salon booking')
@ApiBearerAuth('access-token')
@ApiHeader({ name: 'x-branch-id', required: false, description: 'Branch to manage' })
@Controller({ path: 'shop/salon', version: '1' })
export class ShopSalonController {
  constructor(private readonly salon: SalonService) {}

  @Get('config')
  @ApiOperation({ summary: 'Slot length, team and the service menu (salons only)' })
  config(@CurrentShop() shop: ShopPrincipal): Promise<SalonConfigView> {
    return this.salon.getConfig(shop);
  }

  @Put('config')
  @ApiOperation({ summary: 'Save slot length, team and the service menu (owner or manager)' })
  save(
    @CurrentShop() shop: ShopPrincipal,
    @Body() body: SaveSalonConfigDto,
  ): Promise<SalonConfigView> {
    return this.salon.saveConfig(shop, body);
  }

  @Get('schedule')
  @ApiOperation({ summary: 'One day: each person with their appointments' })
  schedule(
    @CurrentShop() shop: ShopPrincipal,
    @Query() query: SalonScheduleQueryDto,
  ): Promise<SalonScheduleView> {
    return this.salon.schedule(shop, query.date);
  }

  @Post('walk-in')
  @ApiOperation({
    summary: 'A customer walked in: assign free staff for the chosen services and hold the time',
  })
  walkIn(@CurrentShop() shop: ShopPrincipal, @Body() body: SalonWalkInDto) {
    return this.salon.walkIn(shop, body);
  }

  @Post('requests/:requestId/assign')
  @ApiOperation({ summary: 'Choose who does which service on a booking (owner or manager)' })
  assign(
    @CurrentShop() shop: ShopPrincipal,
    @Param('requestId') requestId: string,
    @Body() body: AssignSalonStaffDto,
  ) {
    return this.salon.assignStaff(shop, requestId, body);
  }
}

/** Customer side: the salon menu and which slots are free. */
@ApiTags('Salon booking')
@ApiBearerAuth('access-token')
@Controller({ path: 'marketplace/salons', version: '1' })
export class ConsumerSalonController {
  constructor(private readonly salon: SalonService) {}

  @Get(':shopId/menu')
  @ApiOperation({ summary: "A salon's services, prices and durations" })
  menu(@Param('shopId') shopId: string): Promise<SalonMenuView> {
    return this.salon.menuForCustomer(shopId);
  }

  @Get(':shopId/slots')
  @ApiOperation({
    summary:
      'Slots for a date, each Available, Pending, Booked or Unavailable for the chosen services',
  })
  slots(
    @Param('shopId') shopId: string,
    @Query() query: SalonSlotsQueryDto,
  ): Promise<SalonSlotsView> {
    return this.salon.slotsForCustomer(shopId, query.date, query.serviceIds ?? []);
  }
}
