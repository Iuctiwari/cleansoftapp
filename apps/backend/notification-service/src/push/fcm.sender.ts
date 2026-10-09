import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { PushMessage } from './push.types';

interface ServiceAccount {
  readonly project_id: string;
  readonly client_email: string;
  readonly private_key: string;
  readonly token_uri: string;
}

/** Outcome of sending one message to one device. */
export type FcmResult = 'sent' | 'invalid_token' | 'failed';

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const ACCESS_TOKEN_MARGIN_MS = 60_000;
const REQUEST_TIMEOUT_MS = 8_000;

/**
 * Sends push notifications through Firebase Cloud Messaging (HTTP v1 API).
 *
 * Switched off until a Firebase service-account key is configured, so the
 * service behaves exactly as before without one:
 *   FCM_SERVICE_ACCOUNT_FILE = path to the downloaded key (JSON), or
 *   FCM_SERVICE_ACCOUNT_JSON = the key's JSON text.
 *
 * Google's login is done with Node's own crypto (a signed JWT exchanged for a
 * short-lived access token), so no Firebase SDK is needed.
 */
@Injectable()
export class FcmSender {
  private readonly logger = new Logger(FcmSender.name);
  private readonly account: ServiceAccount | null;
  private accessToken?: { readonly value: string; readonly expiresAt: number };

  constructor(configService: ConfigService) {
    this.account = this.load(
      configService.get<string>('FCM_SERVICE_ACCOUNT_FILE')?.trim(),
      configService.get<string>('FCM_SERVICE_ACCOUNT_JSON')?.trim(),
    );
    if (this.account) {
      this.logger.log(`Push notifications enabled (Firebase project ${this.account.project_id})`);
    } else {
      this.logger.warn('Push notifications are switched off: no Firebase service-account key set');
    }
  }

  get enabled(): boolean {
    return this.account !== null;
  }

  async send(token: string, message: PushMessage): Promise<FcmResult> {
    if (!this.account) return 'failed';
    try {
      let response = await this.post(token, message, await this.authToken());
      if (response.status === 401) {
        // The cached access token was rejected: get a new one once.
        this.accessToken = undefined;
        response = await this.post(token, message, await this.authToken());
      }
      if (response.ok) return 'sent';

      const body = (await response.json().catch(() => ({}))) as {
        readonly error?: {
          readonly status?: string;
          readonly message?: string;
          readonly details?: readonly { readonly errorCode?: string }[];
        };
      };
      const code = body.error?.details?.find((detail) => detail.errorCode)?.errorCode;
      // The phone uninstalled the app or the token is not a valid FCM token:
      // it will never work again, so the caller removes it.
      if (response.status === 404 || code === 'UNREGISTERED') return 'invalid_token';
      if (response.status === 400 && /registration token/i.test(body.error?.message ?? '')) {
        return 'invalid_token';
      }
      this.logger.warn(
        `FCM rejected a message: HTTP ${response.status} ${body.error?.status ?? ''}`,
      );
      return 'failed';
    } catch (error) {
      this.logger.warn(
        `FCM request failed: ${error instanceof Error ? error.message : String(error)}`,
      );
      return 'failed';
    }
  }

  private async post(token: string, message: PushMessage, accessToken: string): Promise<Response> {
    return fetch(
      `https://fcm.googleapis.com/v1/projects/${this.account!.project_id}/messages:send`,
      {
        method: 'POST',
        headers: { authorization: `Bearer ${accessToken}`, 'content-type': 'application/json' },
        body: JSON.stringify({
          message: {
            token,
            notification: { title: message.title, body: message.body },
            // FCM data values must all be strings.
            data: Object.fromEntries(
              Object.entries(message.data ?? {}).map(([key, value]) => [key, String(value)]),
            ),
            android: {
              priority: 'HIGH',
              notification: { channel_id: 'nexoraa_default' },
            },
          },
        }),
        signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
      },
    );
  }

  private async authToken(): Promise<string> {
    if (this.accessToken && this.accessToken.expiresAt - ACCESS_TOKEN_MARGIN_MS > Date.now()) {
      return this.accessToken.value;
    }
    const account = this.account!;
    const now = Math.floor(Date.now() / 1000);
    const encode = (value: object): string =>
      Buffer.from(JSON.stringify(value)).toString('base64url');
    const unsigned = `${encode({ alg: 'RS256', typ: 'JWT' })}.${encode({
      iss: account.client_email,
      scope: FCM_SCOPE,
      aud: account.token_uri,
      iat: now,
      exp: now + 3600,
    })}`;
    const signature = createSign('RSA-SHA256')
      .update(unsigned)
      .sign(account.private_key, 'base64url');

    const response = await fetch(account.token_uri, {
      method: 'POST',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: `${unsigned}.${signature}`,
      }),
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
    if (!response.ok) throw new Error(`Google sign-in for push failed: HTTP ${response.status}`);
    const body = (await response.json()) as { access_token: string; expires_in: number };
    this.accessToken = { value: body.access_token, expiresAt: Date.now() + body.expires_in * 1000 };
    return body.access_token;
  }

  private load(file?: string, json?: string): ServiceAccount | null {
    try {
      const raw = file ? readFileSync(file, 'utf8') : json;
      if (!raw) return null;
      const parsed = JSON.parse(raw) as Partial<ServiceAccount>;
      if (!parsed.project_id || !parsed.client_email || !parsed.private_key) {
        this.logger.error('The Firebase service-account key is missing required fields');
        return null;
      }
      return {
        project_id: parsed.project_id,
        client_email: parsed.client_email,
        private_key: parsed.private_key,
        token_uri: parsed.token_uri ?? 'https://oauth2.googleapis.com/token',
      };
    } catch (error) {
      this.logger.error(
        `Could not read the Firebase service-account key: ${error instanceof Error ? error.message : String(error)}`,
      );
      return null;
    }
  }
}
