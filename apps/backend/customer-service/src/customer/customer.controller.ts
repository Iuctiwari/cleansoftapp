import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiQuery,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import {
  CreateCustomerDto,
  CustomerErrorResponseDto,
  CustomerPageResponseDto,
  CustomerResponseDto,
  CustomerStatisticsResponseDto,
  ListCustomersQueryDto,
  UpdateCustomerDto,
} from './customer.dto';
import { type CustomerRequest, CustomerScopeGuard } from './customer.guard';
import { CustomerService } from './customer.service';
import type {
  CustomerPage,
  CustomerRecord,
  CustomerScope,
  CustomerStatistics,
} from './customer.types';

function getCustomerScope(request: CustomerRequest): CustomerScope {
  if (!request.customerScope) throw new Error('Customer scope guard was not applied');
  return request.customerScope;
}

@ApiTags('Customers')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(CustomerScopeGuard)
@Controller('customers')
export class CustomerController {
  constructor(private readonly customerService: CustomerService) {}

  @Post()
  @ApiOperation({ summary: 'Create a customer in the authenticated tenant and branch' })
  @ApiBody({ type: CreateCustomerDto })
  @ApiCreatedResponse({ description: 'Customer created.', type: CustomerResponseDto })
  @ApiBadRequestResponse({
    description: 'Request validation failed.',
    type: CustomerErrorResponseDto,
  })
  @ApiUnauthorizedResponse({
    description: 'Authentication is required.',
    type: CustomerErrorResponseDto,
  })
  @ApiForbiddenResponse({
    description: 'Tenant or branch scope is unavailable.',
    type: CustomerErrorResponseDto,
  })
  create(
    @Req() request: CustomerRequest,
    @Body() body: CreateCustomerDto,
  ): Promise<CustomerRecord> {
    return this.customerService.create(getCustomerScope(request), body);
  }

  @Get()
  @ApiOperation({ summary: 'List and search customers with server-side pagination' })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1, minimum: 1 })
  @ApiQuery({
    name: 'limit',
    required: false,
    type: Number,
    example: 20,
    minimum: 1,
    maximum: 100,
  })
  @ApiQuery({
    name: 'search',
    required: false,
    type: String,
    maxLength: 120,
    description: 'Case-insensitive name or partial/suffix mobile search.',
  })
  @ApiOkResponse({ description: 'Requested customer page.', type: CustomerPageResponseDto })
  @ApiBadRequestResponse({
    description: 'Pagination or search validation failed.',
    type: CustomerErrorResponseDto,
  })
  @ApiUnauthorizedResponse({
    description: 'Authentication is required.',
    type: CustomerErrorResponseDto,
  })
  @ApiForbiddenResponse({
    description: 'Tenant or branch scope is unavailable.',
    type: CustomerErrorResponseDto,
  })
  list(
    @Req() request: CustomerRequest,
    @Query() query: ListCustomersQueryDto,
  ): Promise<CustomerPage> {
    return this.customerService.list(getCustomerScope(request), query);
  }

  @Get('statistics')
  @ApiOperation({ summary: 'Get unfiltered customer statistics for the authenticated branch' })
  @ApiOkResponse({ type: CustomerStatisticsResponseDto })
  @ApiUnauthorizedResponse({ type: CustomerErrorResponseDto })
  @ApiForbiddenResponse({ type: CustomerErrorResponseDto })
  statistics(@Req() request: CustomerRequest): Promise<CustomerStatistics> {
    return this.customerService.statistics(getCustomerScope(request));
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a customer in the authenticated tenant and branch' })
  @ApiParam({
    name: 'id',
    description: 'Customer MongoDB ObjectId.',
    example: '64f0c18f7c4d2f0012ab34cd',
    schema: { type: 'string', pattern: '^[0-9a-fA-F]{24}$' },
  })
  @ApiOkResponse({ description: 'Customer details.', type: CustomerResponseDto })
  @ApiUnauthorizedResponse({
    description: 'Authentication is required.',
    type: CustomerErrorResponseDto,
  })
  @ApiForbiddenResponse({
    description: 'Tenant or branch scope is unavailable.',
    type: CustomerErrorResponseDto,
  })
  @ApiNotFoundResponse({
    description: 'Customer not found within the current scope.',
    type: CustomerErrorResponseDto,
  })
  getById(@Req() request: CustomerRequest, @Param('id') id: string): Promise<CustomerRecord> {
    return this.customerService.getById(getCustomerScope(request), id);
  }

  @Patch(':id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update mutable customer profile fields' })
  @ApiParam({
    name: 'id',
    description: 'Customer MongoDB ObjectId.',
    example: '64f0c18f7c4d2f0012ab34cd',
    schema: { type: 'string', pattern: '^[0-9a-fA-F]{24}$' },
  })
  @ApiBody({
    type: UpdateCustomerDto,
    description: 'At least one documented mutable field must be supplied.',
  })
  @ApiOkResponse({ description: 'Updated customer.', type: CustomerResponseDto })
  @ApiBadRequestResponse({
    description: 'Request validation failed.',
    type: CustomerErrorResponseDto,
  })
  @ApiUnauthorizedResponse({
    description: 'Authentication is required.',
    type: CustomerErrorResponseDto,
  })
  @ApiForbiddenResponse({
    description: 'Tenant or branch scope is unavailable.',
    type: CustomerErrorResponseDto,
  })
  @ApiNotFoundResponse({
    description: 'Customer not found within the current scope.',
    type: CustomerErrorResponseDto,
  })
  update(
    @Req() request: CustomerRequest,
    @Param('id') id: string,
    @Body() body: UpdateCustomerDto,
  ): Promise<CustomerRecord> {
    return this.customerService.update(getCustomerScope(request), id, body);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Soft-delete a customer in the authenticated tenant and branch' })
  @ApiParam({
    name: 'id',
    description: 'Customer MongoDB ObjectId.',
    example: '64f0c18f7c4d2f0012ab34cd',
    schema: { type: 'string', pattern: '^[0-9a-fA-F]{24}$' },
  })
  @ApiNoContentResponse({ description: 'Customer soft-deleted successfully.' })
  @ApiUnauthorizedResponse({
    description: 'Authentication is required.',
    type: CustomerErrorResponseDto,
  })
  @ApiForbiddenResponse({
    description: 'Tenant or branch scope is unavailable.',
    type: CustomerErrorResponseDto,
  })
  @ApiNotFoundResponse({
    description: 'Customer not found within the current scope.',
    type: CustomerErrorResponseDto,
  })
  delete(@Req() request: CustomerRequest, @Param('id') id: string): Promise<void> {
    return this.customerService.delete(getCustomerScope(request), id);
  }
}
