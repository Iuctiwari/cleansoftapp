import { timingSafeEqual } from 'node:crypto';

import {
  BadRequestException,
  Body,
  Controller,
  ForbiddenException,
  Headers,
  HttpCode,
  Injectable,
  Post,
  Req,
  UnauthorizedException,
  type NestMiddleware,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiBearerAuth, ApiExcludeController, ApiOperation, ApiTags } from '@nestjs/swagger';

import type { NotificationRequest } from '../notification/notification.types';
import { PushService, type RegisterDeviceInput } from './push.service';
import type { PushAudience, PushMessage, PushOutcome } from './push.types';

function scopeOf(
  request: NotificationRequest,
): NonNullable<NotificationRequest['notificationScope']> {
  if (!request.notificationScope)
    throw new UnauthorizedException('A valid bearer token is required');
  return request.notificationScope;
}

/** Shop users (owner, manager, worker): register this phone for pushes. */
@ApiTags('Push devices')
@ApiBearerAuth()
@Controller({ path: 'push/devices', version: '1' })
export class PushDeviceController {
  constructor(private readonly push: PushService) {}

  @Post()
  @HttpCode(204)
  @ApiOperation({ summary: 'Register (or refresh) this phone for push notifications' })
  async register(
    @Req() request: NotificationRequest,
    @Body() body: RegisterDeviceInput,
  ): Promise<void> {
    await this.push.registerShopDevice(scopeOf(request), body ?? {});
  }

  @Post('unregister')
  @HttpCode(204)
  @ApiOperation({ summary: 'Stop push notifications to this phone (on sign out)' })
  async unregister(
    @Req() request: NotificationRequest,
    @Body() body: { token?: unknown },
  ): Promise<void> {
    await this.push.unregister(body?.token, scopeOf(request).actorId);
  }
}

// ── Customers ───────────────────────────────────────────────────────────────

export interface ConsumerPushRequest {
  readonly headers: Readonly<Record<string, string | string[] | undefined>>;
  consumerId?: string;
}

/** Resolves the signed-in customer through auth-service. */
@Injectable()
export class ConsumerPushAuthMiddleware implements NestMiddleware {
  constructor(private readonly configService: ConfigService) {}

  async use(request: ConsumerPushRequest, _response: unknown, next: () => void): Promise<void> {
    const raw = request.headers.authorization;
    const authorization = Array.isArray(raw) ? raw[0] : raw;
    if (!authorization?.startsWith('Bearer ')) {
      throw new UnauthorizedException('A valid bearer token is required');
    }
    const base = this.configService.get<string>(
      'AUTH_SERVICE_BASE_URL',
      'http://localhost:3001/api',
    );
    let response: Response;
    try {
      response = await fetch(`${base.replace(/\/$/, '')}/v1/auth/consumer/context`, {
        headers: { authorization },
        signal: AbortSignal.timeout(5_000),
      });
    } catch {
      throw new UnauthorizedException('Authentication service is unavailable');
    }
    if (response.status === 403) throw new ForbiddenException('A customer account is required');
    if (!response.ok) throw new UnauthorizedException('Invalid or expired access token');
    const data = ((await response.json()) as { data?: { actorId?: string; kind?: string } }).data;
    if (data?.kind !== 'consumer' || !data.actorId) {
      throw new UnauthorizedException('Invalid authenticated context');
    }
    request.consumerId = data.actorId;
    next();
  }
}

/** Marketplace customers: register this phone for pushes. */
@ApiTags('Push devices')
@ApiBearerAuth()
@Controller({ path: 'push/consumer/devices', version: '1' })
export class ConsumerPushDeviceController {
  constructor(private readonly push: PushService) {}

  private consumerOf(request: ConsumerPushRequest): string {
    if (!request.consumerId) throw new UnauthorizedException('A customer session is required');
    return request.consumerId;
  }

  @Post()
  @HttpCode(204)
  @ApiOperation({ summary: 'Register (or refresh) this phone for push notifications' })
  async register(
    @Req() request: ConsumerPushRequest,
    @Body() body: RegisterDeviceInput,
  ): Promise<void> {
    await this.push.registerConsumerDevice(this.consumerOf(request), body ?? {});
  }

  @Post('unregister')
  @HttpCode(204)
  @ApiOperation({ summary: 'Stop push notifications to this phone (on sign out)' })
  async unregister(
    @Req() request: ConsumerPushRequest,
    @Body() body: { token?: unknown },
  ): Promise<void> {
    await this.push.unregister(body?.token, this.consumerOf(request));
  }
}

// ── Other services ──────────────────────────────────────────────────────────

interface InternalPushBody {
  readonly audience?: {
    readonly userId?: unknown;
    readonly consumerId?: unknown;
    readonly tenantId?: unknown;
    readonly branchId?: unknown;
    readonly excludeUserId?: unknown;
    readonly ownersOnly?: unknown;
  };
  readonly title?: unknown;
  readonly body?: unknown;
  readonly data?: unknown;
}

const text = (value: unknown): string | undefined =>
  typeof value === 'string' && value.trim() ? value.trim() : undefined;

/**
 * Service-to-service only (marketplace-service, order-service, the daily
 * overdue job). Protected by the shared INTERNAL_SERVICE_SECRET; never called
 * by the app.
 */
@ApiExcludeController()
@Controller({ path: 'internal/push', version: '1' })
export class PushInternalController {
  constructor(
    private readonly push: PushService,
    private readonly configService: ConfigService,
  ) {}

  @Post()
  @HttpCode(200)
  async send(
    @Headers('x-internal-secret') secret: string | undefined,
    @Body() input: InternalPushBody,
  ): Promise<PushOutcome> {
    const expected = this.configService.get<string>('INTERNAL_SERVICE_SECRET');
    if (!expected || !secret || !this.equal(secret, expected)) {
      throw new UnauthorizedException('A valid internal service key is required');
    }

    const title = text(input?.title);
    const body = text(input?.body);
    if (!title || !body) throw new BadRequestException('title and body are required');
    const audience = this.audienceOf(input?.audience);
    const data: Record<string, string | number | boolean> = {};
    if (input?.data && typeof input.data === 'object') {
      for (const [key, value] of Object.entries(input.data as Record<string, unknown>)) {
        if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
          data[key] = value;
        }
      }
    }
    const message: PushMessage = { title: title.slice(0, 120), body: body.slice(0, 300), data };
    return this.push.send(audience, message);
  }

  private audienceOf(value: InternalPushBody['audience']): PushAudience {
    const userId = text(value?.userId);
    const consumerId = text(value?.consumerId);
    const tenantId = text(value?.tenantId);
    const branchId = text(value?.branchId);
    if (userId) return { kind: 'user', userId };
    if (consumerId) return { kind: 'consumer', consumerId };
    if (tenantId && value?.ownersOnly === true) return { kind: 'owners', tenantId };
    if (tenantId && branchId) {
      return { kind: 'branch', tenantId, branchId, excludeUserId: text(value?.excludeUserId) };
    }
    throw new BadRequestException('audience needs userId, consumerId, or tenantId and branchId');
  }

  private equal(a: string, b: string): boolean {
    const left = Buffer.from(a);
    const right = Buffer.from(b);
    return left.length === right.length && timingSafeEqual(left, right);
  }
}
