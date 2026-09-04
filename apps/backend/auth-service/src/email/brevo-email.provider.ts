import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import type { EmailProvider, SendEmailOptions, SendEmailResult } from './email.types';

const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';
const DEFAULT_REQUEST_TIMEOUT_MS = 10_000;

@Injectable()
export class BrevoEmailProvider implements EmailProvider {
  private readonly logger = new Logger(BrevoEmailProvider.name);
  private readonly apiKey: string;
  private readonly senderEmail: string;
  private readonly senderName: string;

  constructor(private readonly configService: ConfigService) {
    this.apiKey = String(this.configService.get<string>('BREVO_API_KEY') ?? '').trim();
    this.senderEmail = String(
      this.configService.get<string>('BREVO_SENDER_EMAIL') ?? 'noreply@nexoraa.com',
    ).trim();
    this.senderName = String(
      this.configService.get<string>('BREVO_SENDER_NAME') ?? 'Nexoraa CleanSoft',
    ).trim();
  }

  async send(options: SendEmailOptions): Promise<SendEmailResult> {
    if (!this.apiKey) {
      this.logger.error('Brevo API key is not configured; cannot send email.');
      return {
        success: false,
        error: 'Email service configuration is missing.',
      };
    }

    const payload = {
      sender: {
        name: this.senderName,
        email: this.senderEmail,
      },
      to: options.to.map((recipient) => ({
        email: recipient.email,
        ...(recipient.name ? { name: recipient.name } : {}),
      })),
      subject: options.subject,
      htmlContent: options.htmlContent,
      ...(options.textContent ? { textContent: options.textContent } : {}),
      ...(options.tags?.length ? { tags: [...options.tags] } : {}),
    };

    try {
      const response = await fetch(BREVO_API_URL, {
        method: 'POST',
        headers: {
          accept: 'application/json',
          'content-type': 'application/json',
          'api-key': this.apiKey,
        },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(DEFAULT_REQUEST_TIMEOUT_MS),
      });

      if (!response.ok) {
        const status = response.status;
        let responseBody = '';
        try {
          responseBody = await response.text();
        } catch {
          // Ignore body read failures
        }
        // Log status code and non-sensitive error summary without exposing recipient or secrets
        this.logger.error(`Brevo API responded with status ${status}: ${responseBody.slice(0, 200)}`);
        return {
          success: false,
          statusCode: status,
          error: `Brevo API error (status ${status})`,
        };
      }

      const result = (await response.json()) as { messageId?: string };
      this.logger.log(`Brevo transactional email sent successfully (messageId: ${result.messageId ?? 'ok'})`);
      return {
        success: true,
        messageId: result.messageId,
        statusCode: response.status,
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown network failure';
      this.logger.error(`Brevo email request failed: ${message}`);
      return {
        success: false,
        error: message,
      };
    }
  }
}
