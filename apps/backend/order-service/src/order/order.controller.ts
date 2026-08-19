import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  Req,
  Headers,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBadRequestResponse,
  ApiBearerAuth,
  ApiBody,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiInternalServerErrorResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiParam,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JWT_AUTH_NAME } from '@nexoraa/swagger';

import { AssignOrderDto } from './dtos/assign-order.dto';
import { ApplyPaymentProjectionDto } from './dtos/apply-payment-projection.dto';
import { CancelOrderDto } from './dtos/cancel-order.dto';
import { CreateOrderDto } from './dtos/create-order.dto';
import { OrderHistoryResponseDto } from './dtos/order-history-response.dto';
import { OrderQueryDto } from './dtos/order-query.dto';
import { OrderPageResponseDto, OrderResponseDto } from './dtos/order-response.dto';
import { UpdateOrderStatusDto } from './dtos/update-order-status.dto';
import { UpdateOrderDto } from './dtos/update-order.dto';
import { type OrderRequest, OrderScopeGuard } from './order.guard';
import { OrderIdPipe } from './order-id.pipe';
import { OrderService } from './order.service';
import { ConfigService } from '@nestjs/config';
import type { OrderPage, OrderRecord, OrderScope, StatusHistoryRecord } from './order.types';

const ID_PARAMETER = {
  description: 'Order MongoDB ObjectId.',
  example: '64f0c18f7c4d2f0012ab34cd',
  name: 'id',
  schema: { pattern: '^[0-9a-fA-F]{24}$', type: 'string' },
};

function scope(request: OrderRequest): OrderScope {
  if (!request.orderScope) throw new Error('Order scope guard was not applied');
  return request.orderScope;
}

@ApiTags('Orders')
@ApiBearerAuth(JWT_AUTH_NAME)
@UseGuards(OrderScopeGuard)
@Controller({ path: 'orders', version: '1' })
export class OrderController {
  constructor(
    private readonly orderService: OrderService,
    private readonly configService: ConfigService,
  ) {}

  @Post()
  @ApiOperation({
    summary: 'Create an order with authoritative customer/catalog snapshots and totals',
  })
  @ApiBody({ type: CreateOrderDto })
  @ApiCreatedResponse({
    description: 'Receipt-ready order created from authoritative snapshots and totals.',
    type: OrderResponseDto,
  })
  @ApiBadRequestResponse({
    description: 'DTO, customer, service, pricing, or total validation failed.',
  })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Tenant, branch, or RBAC authorization failed.' })
  @ApiNotFoundResponse({ description: 'Customer or catalog reference was not found.' })
  @ApiConflictResponse({ description: 'Atomic order creation conflicted.' })
  @ApiInternalServerErrorResponse({ description: 'Order creation failed unexpectedly.' })
  create(@Req() request: OrderRequest, @Body() body: CreateOrderDto): Promise<OrderRecord> {
    return this.orderService.create(scope(request), body);
  }

  @Post(':id/payment-projection')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Apply an idempotent Payment Management projection' })
  @ApiOkResponse({ description: 'Updated payment projection.', type: OrderResponseDto })
  @ApiBadRequestResponse({ description: 'Projection payload validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Trusted Payment Management context is required.' })
  @ApiConflictResponse({ description: 'Payment exceeds the outstanding amount.' })
  @ApiInternalServerErrorResponse({ description: 'Projection update failed unexpectedly.' })
  applyPaymentProjection(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Headers('x-payment-projection-key') key: string | undefined,
    @Body() body: ApplyPaymentProjectionDto,
  ): Promise<OrderRecord> {
    const expected = this.configService.get<string>('PAYMENT_PROJECTION_KEY');
    if (!expected || key !== expected) {
      throw new ForbiddenException('Trusted Payment Management context is required');
    }
    return this.orderService.applyPaymentProjection(
      scope(request),
      id,
      body.paymentId,
      body.amountMinor,
    );
  }

  @Get()
  @ApiOperation({ summary: 'List, search, filter, sort, and paginate scoped orders' })
  @ApiOkResponse({ description: 'Requested order page.', type: OrderPageResponseDto })
  @ApiBadRequestResponse({ description: 'Query validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Tenant, branch, or RBAC authorization failed.' })
  @ApiInternalServerErrorResponse({ description: 'Order query failed unexpectedly.' })
  list(@Req() request: OrderRequest, @Query() query: OrderQueryDto): Promise<OrderPage> {
    return this.orderService.list(scope(request), query);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get complete scoped order details' })
  @ApiParam(ID_PARAMETER)
  @ApiOkResponse({ description: 'Order details.', type: OrderResponseDto })
  @ApiBadRequestResponse({ description: 'Path parameter validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Tenant, branch, or RBAC authorization failed.' })
  @ApiNotFoundResponse({ description: 'Order not found in the authenticated scope.' })
  @ApiInternalServerErrorResponse({ description: 'Order lookup failed unexpectedly.' })
  get(@Req() request: OrderRequest, @Param('id', OrderIdPipe) id: string): Promise<OrderRecord> {
    return this.orderService.get(scope(request), id);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update mutable fields on a Draft or Received order' })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: UpdateOrderDto })
  @ApiOkResponse({ description: 'Updated order.', type: OrderResponseDto })
  @ApiBadRequestResponse({ description: 'DTO, pricing, or total validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Tenant, branch, or RBAC authorization failed.' })
  @ApiNotFoundResponse({ description: 'Order not found in the authenticated scope.' })
  @ApiConflictResponse({ description: 'Order is no longer editable or changed concurrently.' })
  @ApiInternalServerErrorResponse({ description: 'Order update failed unexpectedly.' })
  update(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: UpdateOrderDto,
  ): Promise<OrderRecord> {
    return this.orderService.update(scope(request), id, body);
  }

  @Patch(':id/status')
  @ApiOperation({ summary: 'Advance an order through the defined lifecycle' })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: UpdateOrderStatusDto })
  @ApiOkResponse({ description: 'Order status changed.', type: OrderResponseDto })
  @ApiBadRequestResponse({ description: 'Status DTO validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({
    description: 'Tenant, branch, assignment, or RBAC authorization failed.',
  })
  @ApiNotFoundResponse({ description: 'Order not found in the authenticated scope.' })
  @ApiConflictResponse({ description: 'Transition is invalid, out of sequence, or concurrent.' })
  @ApiInternalServerErrorResponse({ description: 'Status transition failed unexpectedly.' })
  changeStatus(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: UpdateOrderStatusDto,
  ): Promise<OrderRecord> {
    return this.orderService.changeStatus(scope(request), id, body);
  }

  @Post(':id/assign')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Store a worker assignment on a scoped non-terminal order' })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: AssignOrderDto })
  @ApiOkResponse({ description: 'Order assignment updated.', type: OrderResponseDto })
  @ApiBadRequestResponse({ description: 'Assignment DTO or path validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Tenant, branch, or RBAC authorization failed.' })
  @ApiNotFoundResponse({ description: 'Order was not found in the authenticated scope.' })
  @ApiConflictResponse({ description: 'Assignment update conflicted.' })
  @ApiInternalServerErrorResponse({ description: 'Assignment failed unexpectedly.' })
  assign(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: AssignOrderDto,
  ): Promise<OrderRecord> {
    return this.orderService.assign(scope(request), id, body);
  }

  @Post(':id/cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Cancel a non-terminal order with a mandatory reason' })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: CancelOrderDto })
  @ApiOkResponse({ description: 'Order cancelled.', type: OrderResponseDto })
  @ApiBadRequestResponse({ description: 'A non-empty cancellation reason is required.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Tenant, branch, or RBAC authorization failed.' })
  @ApiNotFoundResponse({ description: 'Order not found in the authenticated scope.' })
  @ApiConflictResponse({ description: 'Order is terminal or changed concurrently.' })
  @ApiInternalServerErrorResponse({ description: 'Cancellation failed unexpectedly.' })
  cancel(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: CancelOrderDto,
  ): Promise<OrderRecord> {
    return this.orderService.cancel(scope(request), id, body);
  }

  @Get(':id/history')
  @ApiOperation({ summary: 'Get immutable status history for a scoped order' })
  @ApiParam(ID_PARAMETER)
  @ApiOkResponse({
    description: 'Chronological order status history.',
    type: [OrderHistoryResponseDto],
  })
  @ApiBadRequestResponse({ description: 'Path parameter validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({
    description: 'Tenant, branch, assignment, or RBAC authorization failed.',
  })
  @ApiNotFoundResponse({ description: 'Order not found in the authenticated scope.' })
  @ApiInternalServerErrorResponse({ description: 'History lookup failed unexpectedly.' })
  history(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
  ): Promise<readonly StatusHistoryRecord[]> {
    return this.orderService.history(scope(request), id);
  }
}
