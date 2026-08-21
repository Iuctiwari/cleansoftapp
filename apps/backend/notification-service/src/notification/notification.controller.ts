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
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiBody,
  ApiCreatedResponse,
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
  CreateNotificationDto,
  MarkAllReadResponseDto,
  NotificationPageResponseDto,
  NotificationResponseDto,
  UnreadCountResponseDto,
} from './notification.dto';
import { NotificationService } from './notification.service';
import {
  NotificationType,
  type NotificationPage,
  type NotificationRecord,
  type NotificationRequest,
  type NotificationUnreadCount,
} from './notification.types';

function scopeOf(
  request: NotificationRequest,
): NonNullable<NotificationRequest['notificationScope']> {
  if (!request.notificationScope) {
    throw new Error('Notification authentication middleware was not applied');
  }
  return request.notificationScope;
}

@ApiTags('Notifications')
@ApiBearerAuth(JWT_AUTH_NAME)
@ApiUnauthorizedResponse({ description: 'Missing, invalid, or expired bearer token.' })
@Controller({ path: 'notifications', version: '1' })
export class NotificationController {
  constructor(private readonly service: NotificationService) {}

  @Post()
  @ApiOperation({
    summary: 'Create a notification for a recipient',
    description:
      'Creates a notification for the given recipient in the authenticated tenant/branch. ' +
      'If the recipient has an active WebSocket connection, the saved notification is pushed ' +
      "immediately via the 'notification:new' event; otherwise it stays in MongoDB until the " +
      'recipient calls GET /notifications.',
  })
  @ApiBody({ type: CreateNotificationDto })
  @ApiCreatedResponse({ description: 'Notification created.', type: NotificationResponseDto })
  create(
    @Req() request: NotificationRequest,
    @Body() body: CreateNotificationDto,
  ): Promise<NotificationRecord> {
    return this.service.create(scopeOf(request), body);
  }

  @Get()
  @ApiOperation({
    summary: "List the authenticated user's notifications",
    description: 'Newest first by default. Only returns notifications addressed to the caller.',
  })
  @ApiQuery({ name: 'page', required: false, type: Number, example: 1 })
  @ApiQuery({ name: 'limit', required: false, type: Number, example: 20 })
  @ApiQuery({
    name: 'isRead',
    required: false,
    type: Boolean,
    description: 'Filter by read state.',
  })
  @ApiQuery({
    name: 'type',
    required: false,
    enum: NotificationType,
    description: 'Filter by type.',
  })
  @ApiQuery({
    name: 'sortDirection',
    required: false,
    enum: ['asc', 'desc'],
    description: 'Sort by createdAt. Defaults to desc (newest first).',
  })
  @ApiOkResponse({ description: 'Requested notification page.', type: NotificationPageResponseDto })
  list(
    @Req() request: NotificationRequest,
    @Query() query: Record<string, unknown>,
  ): Promise<NotificationPage> {
    return this.service.list(scopeOf(request), query);
  }

  @Get('unread-count')
  @ApiOperation({ summary: "Get the authenticated user's unread notification count" })
  @ApiOkResponse({ type: UnreadCountResponseDto })
  unreadCount(@Req() request: NotificationRequest): Promise<NotificationUnreadCount> {
    return this.service.unreadCount(scopeOf(request));
  }

  @Patch(':id/read')
  @ApiOperation({
    summary: 'Mark one notification as read',
    description:
      "Updates MongoDB first, then emits 'notification:read' to the recipient if connected.",
  })
  @ApiParam({ name: 'id', description: 'Notification ObjectId' })
  @ApiOkResponse({ description: 'Updated notification.', type: NotificationResponseDto })
  markRead(
    @Req() request: NotificationRequest,
    @Param('id') id: string,
  ): Promise<NotificationRecord> {
    return this.service.markRead(scopeOf(request), id);
  }

  @Patch('read-all')
  @ApiOperation({
    summary: "Mark all of the authenticated user's unread notifications as read",
    description:
      "Updates MongoDB first, then emits 'notification:read-all' to the recipient if connected.",
  })
  @ApiOkResponse({ type: MarkAllReadResponseDto })
  markAllRead(@Req() request: NotificationRequest): Promise<{ modifiedCount: number }> {
    return this.service.markAllRead(scopeOf(request));
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: "Delete one of the authenticated user's notifications" })
  @ApiParam({ name: 'id', description: 'Notification ObjectId' })
  @ApiNoContentResponse({ description: 'Notification deleted.' })
  async remove(@Req() request: NotificationRequest, @Param('id') id: string): Promise<void> {
    await this.service.remove(scopeOf(request), id);
  }
}
