import { Logger } from '@nestjs/common';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Server, Socket } from 'socket.io';

import { NotificationAuthResolver } from './notification-auth.resolver';
import type { NotificationRecord, NotificationScope } from './notification.types';

/**
 * Each connected socket joins exactly one room keyed to its own authenticated
 * tenant/branch/recipient. There is no subscribe API, so a socket can never join
 * — and therefore never receive — another recipient's room.
 */
function recipientRoom(tenantId: string, branchId: string, recipientId: string): string {
  return `notifications:${tenantId}:${branchId}:${recipientId}`;
}

@WebSocketGateway({ cors: { origin: '*' }, namespace: '/notifications' })
export class NotificationGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  private readonly server!: Server;

  private readonly logger = new Logger(NotificationGateway.name);
  private readonly socketScopes = new Map<string, NotificationScope>();

  constructor(private readonly authResolver: NotificationAuthResolver) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      const authorization = this.extractAuthorization(client);
      const branchId = this.extractBranchId(client);
      const scope = await this.authResolver.resolve(authorization, branchId);
      this.socketScopes.set(client.id, scope);
      await client.join(recipientRoom(scope.tenantId, scope.branchId, scope.actorId));
      this.logger.log(`Notification socket connected for recipient ${scope.actorId}`);
    } catch (error) {
      this.logger.warn(`Rejected notification socket connection: ${(error as Error).message}`);
      client.emit('notification:error', { message: 'Authentication failed' });
      client.disconnect(true);
    }
  }

  handleDisconnect(client: Socket): void {
    const scope = this.socketScopes.get(client.id);
    this.socketScopes.delete(client.id);
    if (scope) this.logger.log(`Notification socket disconnected for recipient ${scope.actorId}`);
  }

  emitNew(record: NotificationRecord): void {
    this.server
      .to(recipientRoom(record.tenantId, record.branchId, record.recipientId))
      .emit('notification:new', record);
  }

  emitRead(record: NotificationRecord): void {
    this.server
      .to(recipientRoom(record.tenantId, record.branchId, record.recipientId))
      .emit('notification:read', record);
  }

  emitReadAll(scope: NotificationScope, modifiedCount: number): void {
    this.server
      .to(recipientRoom(scope.tenantId, scope.branchId, scope.actorId))
      .emit('notification:read-all', { modifiedCount });
  }

  private extractAuthorization(client: Socket): string {
    const fromAuth = client.handshake.auth?.token as unknown;
    const fromHeader = client.handshake.headers.authorization;
    const fromQuery = client.handshake.query?.token;
    const raw =
      (typeof fromAuth === 'string' && fromAuth) ||
      (typeof fromHeader === 'string' && fromHeader) ||
      (typeof fromQuery === 'string' && fromQuery) ||
      undefined;
    if (!raw) throw new UnauthorizedTokenError();
    return raw.startsWith('Bearer ') ? raw : `Bearer ${raw}`;
  }

  private extractBranchId(client: Socket): string | undefined {
    const fromHeader = client.handshake.headers['x-branch-id'];
    const fromQuery = client.handshake.query?.branchId;
    if (typeof fromHeader === 'string') return fromHeader;
    if (typeof fromQuery === 'string') return fromQuery;
    return undefined;
  }
}

class UnauthorizedTokenError extends Error {
  constructor() {
    super('Missing authentication token');
  }
}
