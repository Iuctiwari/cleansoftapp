import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export type PushTarget =
  | { readonly consumerId: string }
  | { readonly tenantId: string; readonly branchId: string };

/**
 * Asks notification-service to send a phone push. Best effort: a push problem
 * (no Firebase key yet, service down) must never fail a booking, so errors are
 * logged and swallowed.
 */
@Injectable()
export class PushClient {
  private readonly logger = new Logger(PushClient.name);

  constructor(private readonly configService: ConfigService) {}

  async send(
    audience: PushTarget,
    title: string,
    body: string,
    data: Readonly<Record<string, string>> = {},
  ): Promise<void> {
    const secret = this.configService.get<string>('INTERNAL_SERVICE_SECRET');
    if (!secret) return;
    const base = this.configService
      .get<string>('NOTIFICATION_SERVICE_BASE_URL', 'http://localhost:3005')
      .replace(/\/$/, '');
    try {
      const response = await fetch(`${base}/api/v1/internal/push`, {
        method: 'POST',
        headers: { 'content-type': 'application/json', 'x-internal-secret': secret },
        body: JSON.stringify({ audience, title, body, data }),
        signal: AbortSignal.timeout(5_000),
      });
      if (!response.ok) this.logger.warn(`Push request refused: HTTP ${response.status}`);
    } catch (error) {
      this.logger.warn(
        `Push request failed: ${error instanceof Error ? error.message : String(error)}`,
      );
    }
  }
}
