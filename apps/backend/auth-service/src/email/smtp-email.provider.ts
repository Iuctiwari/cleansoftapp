import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, type Transporter } from 'nodemailer';

import type { EmailProvider, SendEmailOptions, SendEmailResult } from './email.types';

/**
 * Sends email through any SMTP server (e.g. Gmail with an app password:
 * SMTP_HOST=smtp.gmail.com, SMTP_PORT=587, SMTP_USER=<gmail>, SMTP_PASS=<app password>).
 * Selected by EmailModule whenever SMTP_HOST is configured; otherwise Brevo is used.
 */
@Injectable()
export class SmtpEmailProvider implements EmailProvider {
  private readonly logger = new Logger(SmtpEmailProvider.name);
  private readonly transporter: Transporter | null;
  private readonly from: string;

  constructor(configService: ConfigService) {
    const get = (key: string) => configService.get<string>(key)?.trim() || undefined;
    const host = get('SMTP_HOST');
    const user = get('SMTP_USER');
    const port = Number(get('SMTP_PORT') ?? 587);
    // Gmail shows app passwords in groups of four ("abcd efgh ..."); spaces are not part of it.
    const pass = get('SMTP_PASS')?.replace(/\s+/g, '');

    this.from = `"${get('SMTP_FROM_NAME') ?? 'Nexoraa'}" <${get('SMTP_FROM_EMAIL') ?? user ?? ''}>`;
    this.transporter =
      host && user && pass
        ? createTransport({
            host,
            port,
            secure: port === 465, // 465 = implicit TLS; 587 upgrades with STARTTLS
            auth: { user, pass },
            connectionTimeout: 10_000,
            greetingTimeout: 10_000,
            socketTimeout: 15_000,
          })
        : null;
  }

  async send(options: SendEmailOptions): Promise<SendEmailResult> {
    if (!this.transporter) {
      this.logger.error('SMTP is not fully configured (SMTP_HOST, SMTP_USER, SMTP_PASS).');
      return { success: false, error: 'Email service configuration is missing.' };
    }
    try {
      const info = await this.transporter.sendMail({
        from: this.from,
        to: options.to.map((r) => (r.name ? `"${r.name}" <${r.email}>` : r.email)),
        subject: options.subject,
        html: options.htmlContent,
        ...(options.textContent ? { text: options.textContent } : {}),
      });
      this.logger.log(`SMTP email sent successfully (messageId: ${info.messageId})`);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown SMTP failure';
      this.logger.error(`SMTP email failed: ${message}`);
      return { success: false, error: message };
    }
  }
}
