import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

import { NotificationType } from './notification.types';

export class CreateNotificationDto {
  @ApiProperty({
    example: '64f0c18f7c4d2f0012ab34cd',
    description: 'MongoDB ObjectId of the user receiving this notification.',
  })
  recipientId!: string;

  @ApiProperty({ example: 'New order assigned', maxLength: 200 })
  title!: string;

  @ApiProperty({ example: 'You have been assigned order ORD-B01-1024.', maxLength: 2000 })
  message!: string;

  @ApiProperty({ enum: NotificationType, example: NotificationType.WORKER_ASSIGNED })
  type!: NotificationType;

  @ApiPropertyOptional({ example: 'Order', maxLength: 100, description: 'Kind of related entity.' })
  entityType?: string;

  @ApiPropertyOptional({
    example: '64f0c18f7c4d2f0012ab34ee',
    description: 'MongoDB ObjectId of the related entity, when entityType is set.',
  })
  entityId?: string;

  @ApiPropertyOptional({
    example: '64f0c18f7c4d2f0012ab34ff',
    description: 'MongoDB ObjectId of the related order, when applicable.',
  })
  orderId?: string;
}

export class NotificationResponseDto {
  @ApiProperty({ example: '64f0c18f7c4d2f0012ab3411' })
  id!: string;

  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34aa' })
  tenantId!: string;

  @ApiProperty({ example: 'branch_01' })
  branchId!: string;

  @ApiProperty({ example: '64f0c18f7c4d2f0012ab34cd' })
  recipientId!: string;

  @ApiProperty({ example: 'New order assigned' })
  title!: string;

  @ApiProperty({ example: 'You have been assigned order ORD-B01-1024.' })
  message!: string;

  @ApiProperty({ enum: NotificationType, example: NotificationType.WORKER_ASSIGNED })
  type!: NotificationType;

  @ApiPropertyOptional({ example: 'Order' })
  entityType?: string;

  @ApiPropertyOptional({ example: '64f0c18f7c4d2f0012ab34ee' })
  entityId?: string;

  @ApiPropertyOptional({ example: '64f0c18f7c4d2f0012ab34ff' })
  orderId?: string;

  @ApiProperty({ example: false })
  isRead!: boolean;

  @ApiProperty({ example: '2026-08-19T10:30:00.000Z', format: 'date-time' })
  createdAt!: Date;

  @ApiProperty({ example: '2026-08-19T10:30:00.000Z', format: 'date-time' })
  updatedAt!: Date;
}

export class NotificationPageResponseDto {
  @ApiProperty({ type: [NotificationResponseDto] })
  items!: NotificationResponseDto[];

  @ApiProperty({ example: 42, minimum: 0 })
  total!: number;

  @ApiProperty({ example: 1, minimum: 1 })
  page!: number;

  @ApiProperty({ example: 20, minimum: 1 })
  limit!: number;

  @ApiProperty({ example: 3, minimum: 0 })
  totalPages!: number;
}

export class UnreadCountResponseDto {
  @ApiProperty({ example: 5, minimum: 0 })
  count!: number;
}

export class MarkAllReadResponseDto {
  @ApiProperty({ example: 5, minimum: 0, description: 'Number of notifications marked as read.' })
  modifiedCount!: number;
}
