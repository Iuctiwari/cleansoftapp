import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

import type { ConsumerPrincipal } from '../platform/marketplace.types';
import { CurrentConsumer } from '../platform/principal.decorators';
import { CreateAddressDto, UpdateAddressDto } from './address.dto';
import { AddressService, type ConsumerAddressView } from './address.service';

@ApiTags('Customer addresses')
@ApiBearerAuth('access-token')
@Controller({ path: 'consumer/addresses', version: '1' })
export class AddressController {
  constructor(private readonly addressService: AddressService) {}

  @Get()
  @ApiOperation({ summary: 'List my saved addresses (default first)' })
  list(@CurrentConsumer() consumer: ConsumerPrincipal): Promise<ConsumerAddressView[]> {
    return this.addressService.list(consumer.consumerId);
  }

  @Post()
  @ApiOperation({ summary: 'Add an address (the first one becomes the default)' })
  create(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Body() body: CreateAddressDto,
  ): Promise<ConsumerAddressView> {
    return this.addressService.create(consumer, body);
  }

  @Patch(':addressId')
  @ApiOperation({ summary: 'Edit an address' })
  update(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Param('addressId') addressId: string,
    @Body() body: UpdateAddressDto,
  ): Promise<ConsumerAddressView> {
    return this.addressService.update(consumer.consumerId, addressId, body);
  }

  @Post(':addressId/default')
  @HttpCode(200)
  @ApiOperation({ summary: 'Make this my default address' })
  setDefault(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Param('addressId') addressId: string,
  ): Promise<ConsumerAddressView> {
    return this.addressService.setDefault(consumer.consumerId, addressId);
  }

  @Delete(':addressId')
  @HttpCode(204)
  @ApiOperation({ summary: 'Delete an address (the last one cannot be deleted)' })
  remove(
    @CurrentConsumer() consumer: ConsumerPrincipal,
    @Param('addressId') addressId: string,
  ): Promise<void> {
    return this.addressService.remove(consumer.consumerId, addressId);
  }
}
