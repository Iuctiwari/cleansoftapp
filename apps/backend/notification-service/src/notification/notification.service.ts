import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Permissions, hasPermission } from '@nexoraa/shared';
import { InjectModel } from '@nestjs/mongoose';
import { DEFAULT_PAGE_NUMBER, DEFAULT_PAGE_SIZE, MAX_PAGE_SIZE } from '@nexoraa/constants';
import { FilterQuery, Model, Types } from 'mongoose';

import { NotificationGateway } from './notification.gateway';
import { NotificationMongoose, type NotificationDocument } from './notification.schema';
import {
  NotificationType,
  type CreateNotificationInput,
  type NotificationListQuery,
  type NotificationPage,
  type NotificationRecord,
  type NotificationScope,
  type NotificationUnreadCount,
} from './notification.types';

const NOTIFICATION_TYPES = new Set<string>(Object.values(NotificationType));
const TITLE_MAX_LENGTH = 200;
const MESSAGE_MAX_LENGTH = 2000;
const ENTITY_TYPE_MAX_LENGTH = 100;

@Injectable()
export class NotificationService {
  constructor(
    @InjectModel(NotificationMongoose.name)
    private readonly notifications: Model<NotificationDocument>,
    private readonly gateway: NotificationGateway,
  ) {}

  async create(
    scope: NotificationScope,
    input: CreateNotificationInput,
  ): Promise<NotificationRecord> {
    this.assertAccess(scope);
    const recipientId = this.objectId(input.recipientId, 'recipientId');
    const title = this.requiredString(input.title, 'title', TITLE_MAX_LENGTH);
    const message = this.requiredString(input.message, 'message', MESSAGE_MAX_LENGTH);
    const type = this.notificationType(input.type);
    const entityType = this.optionalString(input.entityType, 'entityType', ENTITY_TYPE_MAX_LENGTH);
    const entityId = this.optionalObjectId(input.entityId, 'entityId');
    const orderId = this.optionalObjectId(input.orderId, 'orderId');

    const created = await this.notifications.create({
      _id: new Types.ObjectId(),
      branchId: scope.branchId,
      entityId: entityId ? new Types.ObjectId(entityId) : undefined,
      entityType,
      isRead: false,
      message,
      orderId: orderId ? new Types.ObjectId(orderId) : undefined,
      recipientId: new Types.ObjectId(recipientId),
      tenantId: new Types.ObjectId(scope.tenantId),
      title,
      type,
    });

    const record = this.toRecord(created);
    this.gateway.emitNew(record);
    return record;
  }

  async list(scope: NotificationScope, input: Record<string, unknown>): Promise<NotificationPage> {
    this.assertAccess(scope);
    const query = this.parseListQuery(input);
    const filter: FilterQuery<NotificationDocument> = {
      branchId: scope.branchId,
      recipientId: new Types.ObjectId(scope.actorId),
      tenantId: new Types.ObjectId(scope.tenantId),
      ...(query.isRead === undefined ? {} : { isRead: query.isRead }),
      ...(query.type ? { type: query.type } : {}),
    };
    const skip = (query.page - 1) * query.limit;
    const [documents, total] = await Promise.all([
      this.notifications
        .find(filter)
        .sort({ createdAt: query.sortDirection, _id: query.sortDirection })
        .skip(skip)
        .limit(query.limit)
        .exec(),
      this.notifications.countDocuments(filter).exec(),
    ]);

    return {
      items: documents.map((document) => this.toRecord(document)),
      limit: query.limit,
      page: query.page,
      total,
      totalPages: Math.ceil(total / query.limit),
    };
  }

  async unreadCount(scope: NotificationScope): Promise<NotificationUnreadCount> {
    this.assertAccess(scope);
    const count = await this.notifications
      .countDocuments({
        branchId: scope.branchId,
        isRead: false,
        recipientId: new Types.ObjectId(scope.actorId),
        tenantId: new Types.ObjectId(scope.tenantId),
      })
      .exec();
    return { count };
  }

  async markRead(scope: NotificationScope, id: string): Promise<NotificationRecord> {
    this.assertAccess(scope);
    const notificationId = this.objectId(id, 'id');
    const updated = await this.notifications
      .findOneAndUpdate(
        { ...this.ownedFilter(scope, notificationId) },
        { $set: { isRead: true } },
        { new: true },
      )
      .exec();
    if (!updated) throw new NotFoundException('Notification not found');
    const record = this.toRecord(updated);
    this.gateway.emitRead(record);
    return record;
  }

  async markAllRead(scope: NotificationScope): Promise<{ modifiedCount: number }> {
    this.assertAccess(scope);
    const result = await this.notifications
      .updateMany(
        {
          branchId: scope.branchId,
          isRead: false,
          recipientId: new Types.ObjectId(scope.actorId),
          tenantId: new Types.ObjectId(scope.tenantId),
        },
        { $set: { isRead: true } },
      )
      .exec();
    if (result.modifiedCount > 0) this.gateway.emitReadAll(scope, result.modifiedCount);
    return { modifiedCount: result.modifiedCount };
  }

  async remove(scope: NotificationScope, id: string): Promise<void> {
    this.assertAccess(scope);
    const notificationId = this.objectId(id, 'id');
    const result = await this.notifications
      .deleteOne(this.ownedFilter(scope, notificationId))
      .exec();
    if (result.deletedCount === 0) throw new NotFoundException('Notification not found');
  }

  private assertAccess(scope: NotificationScope): void {
    if (!hasPermission(scope.roleCode, scope.permissions, Permissions.notificationsRead)) {
      throw new ForbiddenException('Notification permission is required');
    }
  }

  private ownedFilter(
    scope: NotificationScope,
    notificationId: string,
  ): FilterQuery<NotificationDocument> {
    return {
      _id: new Types.ObjectId(notificationId),
      branchId: scope.branchId,
      recipientId: new Types.ObjectId(scope.actorId),
      tenantId: new Types.ObjectId(scope.tenantId),
    };
  }

  private parseListQuery(input: Record<string, unknown>): NotificationListQuery {
    const page = this.positiveInt(input.page, DEFAULT_PAGE_NUMBER, 1);
    const limit = this.positiveInt(input.limit, DEFAULT_PAGE_SIZE, 1, MAX_PAGE_SIZE);
    const isRead = this.optionalBoolean(input.isRead, 'isRead');
    const type = input.type === undefined ? undefined : this.notificationType(input.type);
    const sortDirection = input.sortDirection === 'asc' || input.sortDirection === '1' ? 1 : -1;
    return { isRead, limit, page, sortDirection, type };
  }

  private positiveInt(value: unknown, fallback: number, min: number, max?: number): number {
    const parsed = typeof value === 'string' || typeof value === 'number' ? Number(value) : NaN;
    if (!Number.isFinite(parsed) || !Number.isInteger(parsed)) return fallback;
    const clampedMin = Math.max(parsed, min);
    return max === undefined ? clampedMin : Math.min(clampedMin, max);
  }

  private optionalBoolean(value: unknown, field: string): boolean | undefined {
    if (value === undefined) return undefined;
    if (value === 'true' || value === true) return true;
    if (value === 'false' || value === false) return false;
    throw new BadRequestException(`${field} must be a boolean`);
  }

  private notificationType(value: unknown): NotificationType {
    if (typeof value !== 'string' || !NOTIFICATION_TYPES.has(value)) {
      throw new BadRequestException('type is invalid');
    }
    return value as NotificationType;
  }

  private requiredString(value: unknown, field: string, maxLength: number): string {
    if (typeof value !== 'string' || !value.trim()) {
      throw new BadRequestException(`${field} is required`);
    }
    const trimmed = value.trim();
    if (trimmed.length > maxLength) {
      throw new BadRequestException(`${field} must be at most ${maxLength} characters`);
    }
    return trimmed;
  }

  private optionalString(value: unknown, field: string, maxLength: number): string | undefined {
    if (value === undefined) return undefined;
    if (typeof value !== 'string' || !value.trim()) {
      throw new BadRequestException(`${field} must be a non-empty string`);
    }
    const trimmed = value.trim();
    if (trimmed.length > maxLength) {
      throw new BadRequestException(`${field} must be at most ${maxLength} characters`);
    }
    return trimmed;
  }

  private objectId(value: unknown, field: string): string {
    if (typeof value !== 'string' || !Types.ObjectId.isValid(value)) {
      throw new BadRequestException(`${field} must be a MongoDB ObjectId`);
    }
    return value;
  }

  private optionalObjectId(value: unknown, field: string): string | undefined {
    if (value === undefined) return undefined;
    return this.objectId(value, field);
  }

  private toRecord(document: NotificationDocument): NotificationRecord {
    return {
      branchId: document.branchId,
      createdAt: document.createdAt,
      entityId: document.entityId ? String(document.entityId) : undefined,
      entityType: document.entityType,
      id: String(document._id),
      isRead: document.isRead,
      message: document.message,
      orderId: document.orderId ? String(document.orderId) : undefined,
      recipientId: String(document.recipientId),
      tenantId: String(document.tenantId),
      title: document.title,
      type: document.type,
      updatedAt: document.updatedAt,
    };
  }
}
