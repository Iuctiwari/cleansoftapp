import {
  Body,
  Controller,
  ForbiddenException,
  Get,
  Headers,
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
import { ModuleKey, RequireModule } from '@nexoraa/tenant-enforcement-client';

import { ConfigService } from '@nestjs/config';
import { ApplyPaymentProjectionDto } from './dtos/apply-payment-projection.dto';
import { AddOrderNoteDto } from './dtos/add-order-note.dto';
import { AssignOrderDto } from './dtos/assign-order.dto';
import { BulkAssignDto } from './dtos/bulk-assign.dto';
import { CancelOrderDto } from './dtos/cancel-order.dto';
import { CreateOrderDto } from './dtos/create-order.dto';
import { DeclineRequestDto, ResolveDeclineRequestDto } from './dtos/decline-request.dto';
import { RejectAssignmentDto } from './dtos/reject-assignment.dto';
import { OrderHistoryResponseDto } from './dtos/order-history-response.dto';
import { OrderQueryDto } from './dtos/order-query.dto';
import {
  OrderPageResponseDto,
  OrderResponseDto,
  OrderStatisticsResponseDto,
} from './dtos/order-response.dto';
import { UpdateOrderStatusDto } from './dtos/update-order-status.dto';
import { UpdateOrderDto } from './dtos/update-order.dto';
import { OrderEnforcementGuard } from './order-enforcement.guard';
import { OrderIdPipe } from './order-id.pipe';
import { type OrderRequest, OrderScopeGuard } from './order.guard';
import { type BulkAssignResult, OrderService } from './order.service';
import type {
  OrderPage,
  OrderRecord,
  OrderScope,
  OrderStatistics,
  StatusHistoryRecord,
  WorkloadSummary,
} from './order.types';

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
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
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

  @Get('statistics')
  @ApiOperation({ summary: 'Get database-aggregated statistics for the authenticated scope' })
  @ApiOkResponse({ type: OrderStatisticsResponseDto })
  statistics(
    @Req() request: OrderRequest,
    @Query('customerId') customerId?: string,
  ): Promise<OrderStatistics> {
    return this.orderService.statistics(scope(request), customerId);
  }

  @Get('workload')
  @ApiOperation({
    summary: 'Owner/Branch Manager: per-worker task counts for the Worker Tasks screen',
  })
  @ApiOkResponse({ description: 'Per-worker counts, unassigned and pending-decline totals.' })
  @ApiForbiddenResponse({ description: 'Only Owner or Branch Manager.' })
  workload(@Req() request: OrderRequest): Promise<WorkloadSummary> {
    return this.orderService.workload(scope(request));
  }

  @Get('decline-requests')
  @ApiOperation({ summary: 'Owner/Branch Manager: orders whose worker asked to be taken off' })
  @ApiOkResponse({ description: 'Orders with a pending decline request, oldest first.' })
  @ApiForbiddenResponse({ description: 'Only Owner or Branch Manager.' })
  pendingDeclines(@Req() request: OrderRequest): Promise<readonly OrderRecord[]> {
    return this.orderService.listPendingDeclines(scope(request));
  }

  @Post('bulk-assign')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Assign many orders at once (auto = even split by workload, manual = one worker)',
  })
  @ApiBody({ type: BulkAssignDto })
  @ApiOkResponse({ description: 'Plan plus what was assigned, skipped, or failed.' })
  @ApiBadRequestResponse({ description: 'Body validation failed.' })
  @ApiForbiddenResponse({ description: 'Only Owner or Branch Manager.' })
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
  bulkAssign(@Req() request: OrderRequest, @Body() body: BulkAssignDto): Promise<BulkAssignResult> {
    return this.orderService.bulkAssign(scope(request), body);
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
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
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
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
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
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
  assign(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: AssignOrderDto,
  ): Promise<OrderRecord> {
    return this.orderService.assign(scope(request), id, body);
  }

  @Post(':id/assignment/accept')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept the authenticated worker assignment' })
  @ApiParam(ID_PARAMETER)
  @ApiOkResponse({
    description: 'Assignment accepted and order lifecycle updated.',
    type: OrderResponseDto,
  })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Only the assigned worker may accept the assignment.' })
  @ApiNotFoundResponse({ description: 'Order was not found in the authenticated scope.' })
  @ApiConflictResponse({ description: 'Assignment is no longer available to accept.' })
  @ApiInternalServerErrorResponse({ description: 'Assignment acceptance failed unexpectedly.' })
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
  acceptAssignment(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
  ): Promise<OrderRecord> {
    return this.orderService.acceptAssignment(scope(request), id);
  }

  @Post(':id/assignment/decline-request')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Assigned worker asks the owner to be taken off this order (owner decides)',
  })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: DeclineRequestDto })
  @ApiOkResponse({ description: 'Decline request recorded as Pending.', type: OrderResponseDto })
  @ApiForbiddenResponse({ description: 'Only the assigned worker may ask.' })
  @ApiConflictResponse({ description: 'Already pending, or the order can no longer be declined.' })
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
  requestDecline(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: DeclineRequestDto,
  ): Promise<OrderRecord> {
    return this.orderService.requestDecline(scope(request), id, body.reason);
  }

  @Post(':id/assignment/decline-request/approve')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Approve a decline request: the order returns to the unassigned pool' })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: ResolveDeclineRequestDto })
  @ApiOkResponse({
    description: 'Approved; order is Received and unassigned.',
    type: OrderResponseDto,
  })
  @ApiForbiddenResponse({ description: 'Only Owner or Branch Manager.' })
  @ApiConflictResponse({ description: 'No pending request, or the order changed meanwhile.' })
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
  approveDecline(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: ResolveDeclineRequestDto,
  ): Promise<OrderRecord> {
    return this.orderService.resolveDecline(scope(request), id, true, body.note);
  }

  @Post(':id/assignment/decline-request/deny')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Deny a decline request: the worker keeps the order' })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: ResolveDeclineRequestDto })
  @ApiOkResponse({ description: 'Denied; assignment unchanged.', type: OrderResponseDto })
  @ApiForbiddenResponse({ description: 'Only Owner or Branch Manager.' })
  @ApiConflictResponse({ description: 'No pending request.' })
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
  denyDecline(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: ResolveDeclineRequestDto,
  ): Promise<OrderRecord> {
    return this.orderService.resolveDecline(scope(request), id, false, body.note);
  }

  @Post(':id/notes')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Add a note to an order (e.g. a worker reporting a damaged item); append-only',
  })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: AddOrderNoteDto })
  @ApiOkResponse({ description: 'Order including the new note.', type: OrderResponseDto })
  @ApiBadRequestResponse({ description: 'Note validation failed or itemId not on this order.' })
  @ApiNotFoundResponse({ description: 'Order not found (workers only see their own orders).' })
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
  addNote(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: AddOrderNoteDto,
  ): Promise<OrderRecord> {
    return this.orderService.addNote(scope(request), id, body);
  }

  @Post(':id/assignment/reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Owner/Branch Manager: unassign the worker. Workers cannot reject; they use decline-request.',
  })
  @ApiParam(ID_PARAMETER)
  @ApiBody({ type: RejectAssignmentDto })
  @ApiOkResponse({
    description: 'Assignment rejected and order lifecycle updated.',
    type: OrderResponseDto,
  })
  @ApiBadRequestResponse({ description: 'Rejection reason validation failed.' })
  @ApiUnauthorizedResponse({ description: 'A valid JWT is required.' })
  @ApiForbiddenResponse({ description: 'Only the assigned worker may reject the assignment.' })
  @ApiNotFoundResponse({ description: 'Order was not found in the authenticated scope.' })
  @ApiConflictResponse({ description: 'Assignment is no longer available to reject.' })
  @ApiInternalServerErrorResponse({ description: 'Assignment rejection failed unexpectedly.' })
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
  rejectAssignment(
    @Req() request: OrderRequest,
    @Param('id', OrderIdPipe) id: string,
    @Body() body: RejectAssignmentDto,
  ): Promise<OrderRecord> {
    return this.orderService.rejectAssignment(scope(request), id, body.reason);
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
  @UseGuards(OrderEnforcementGuard)
  @RequireModule(ModuleKey.ORDER_MANAGEMENT)
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
