import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Permissions, hasPermission, isOwnerRole } from '@nexoraa/shared';
import type { FilterQuery, Model } from 'mongoose';

import type { NotificationScope } from '../notification/notification.types';
import { FcmSender } from './fcm.sender';
import { PushDeviceMongoose, type PushDeviceDocument } from './push-device.schema';
import {
  MAX_DEVICES_PER_ACCOUNT,
  NO_PUSH,
  type PushAudience,
  type PushMessage,
  type PushOutcome,
} from './push.types';

const TOKEN_MIN_LENGTH = 40;
const TOKEN_MAX_LENGTH = 4096;
const SEND_CONCURRENCY = 5;

export interface RegisterDeviceInput {
  readonly token?: unknown;
  readonly platform?: unknown;
  readonly appVersion?: unknown;
}

@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);

  constructor(
    @InjectModel(PushDeviceMongoose.name)
    private readonly devices: Model<PushDeviceDocument>,
    private readonly sender: FcmSender,
  ) {}

  get enabled(): boolean {
    return this.sender.enabled;
  }

  // ── Registering phones ────────────────────────────────────────────────────

  /** A signed-in shop user's phone. Call again on every app start (token can change). */
  async registerShopDevice(scope: NotificationScope, input: RegisterDeviceInput): Promise<void> {
    const owner = isOwnerRole(scope.roleCode);
    await this.upsert(input, {
      kind: 'shop',
      accountId: scope.actorId,
      tenantId: scope.tenantId,
      branchId: scope.branchId,
      roleCode: scope.roleCode,
      isOwner: owner,
      seesOrders: hasPermission(scope.roleCode, scope.permissions, Permissions.ordersRead),
    });
  }

  /** A signed-in marketplace customer's phone. */
  async registerConsumerDevice(consumerId: string, input: RegisterDeviceInput): Promise<void> {
    await this.upsert(input, { kind: 'consumer', accountId: consumerId });
  }

  /** Signing out: stop pushes to this phone for this account only. */
  async unregister(token: unknown, accountId: string): Promise<void> {
    const value = this.token(token);
    await this.devices.deleteOne({ token: value, accountId }).exec();
  }

  private async upsert(
    input: RegisterDeviceInput,
    fields: Pick<PushDeviceMongoose, 'kind' | 'accountId'> & Partial<PushDeviceMongoose>,
  ): Promise<void> {
    const token = this.token(input.token);
    const now = new Date();
    const platform =
      typeof input.platform === 'string' && input.platform.trim()
        ? input.platform.trim().slice(0, 20)
        : 'android';
    const appVersion =
      typeof input.appVersion === 'string' ? input.appVersion.trim().slice(0, 40) : undefined;

    // Same phone, new account: the token belongs to whoever signed in last.
    await this.devices
      .replaceOne(
        { token },
        {
          token,
          platform,
          ...(appVersion ? { appVersion } : {}),
          ...fields,
          createdAt: now,
          lastSeenAt: now,
        },
        { upsert: true },
      )
      .exec();

    // Keep only the newest phones per account.
    const extra = await this.devices
      .find({ accountId: fields.accountId, kind: fields.kind }, { _id: 1 })
      .sort({ lastSeenAt: -1 })
      .skip(MAX_DEVICES_PER_ACCOUNT)
      .lean()
      .exec();
    if (extra.length > 0) {
      await this.devices.deleteMany({ _id: { $in: extra.map((device) => device._id) } }).exec();
    }
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  /**
   * Best effort: never throws, so a push problem can never break the action
   * (assigning an order, creating a request) that triggered it.
   */
  async send(audience: PushAudience, message: PushMessage): Promise<PushOutcome> {
    if (!this.sender.enabled) return NO_PUSH;
    try {
      const devices = await this.devices.find(this.filterFor(audience), { token: 1 }).lean().exec();
      let sent = 0;
      const dead: string[] = [];
      for (let i = 0; i < devices.length; i += SEND_CONCURRENCY) {
        const batch = devices.slice(i, i + SEND_CONCURRENCY);
        const results = await Promise.all(
          batch.map(async (device) => ({
            token: device.token,
            result: await this.sender.send(device.token, message),
          })),
        );
        for (const { token, result } of results) {
          if (result === 'sent') sent++;
          else if (result === 'invalid_token') dead.push(token);
        }
      }
      if (dead.length > 0) await this.devices.deleteMany({ token: { $in: dead } }).exec();
      return { enabled: true, devices: devices.length, sent, removed: dead.length };
    } catch (error) {
      this.logger.warn(
        `Push send failed: ${error instanceof Error ? error.message : String(error)}`,
      );
      return { enabled: true, devices: 0, sent: 0, removed: 0 };
    }
  }

  filterFor(audience: PushAudience): FilterQuery<PushDeviceDocument> {
    switch (audience.kind) {
      case 'user':
        return { kind: 'shop', accountId: audience.userId };
      case 'consumer':
        return { kind: 'consumer', accountId: audience.consumerId };
      case 'owners':
        return { kind: 'shop', tenantId: audience.tenantId, isOwner: true };
      case 'branch':
        return {
          kind: 'shop',
          tenantId: audience.tenantId,
          seesOrders: true,
          // Owners hear about every branch; everyone else only their own.
          $or: [{ isOwner: true }, { branchId: audience.branchId }],
          ...(audience.excludeUserId ? { accountId: { $ne: audience.excludeUserId } } : {}),
        };
    }
  }

  // ── Input checks ──────────────────────────────────────────────────────────

  private token(value: unknown): string {
    if (typeof value !== 'string') throw new BadRequestException('token is required');
    const token = value.trim();
    if (token.length < TOKEN_MIN_LENGTH || token.length > TOKEN_MAX_LENGTH || /\s/.test(token)) {
      throw new BadRequestException('token is not a valid push token');
    }
    return token;
  }
}
