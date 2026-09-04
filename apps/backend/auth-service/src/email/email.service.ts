import { Inject, Injectable, Logger } from '@nestjs/common';
import {
  EMAIL_PROVIDER,
  type EmailProvider,
  type SendEmailOptions,
  type SendEmailResult,
} from './email.types';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);

  constructor(
    @Inject(EMAIL_PROVIDER)
    private readonly provider: EmailProvider,
  ) {}

  async sendEmail(options: SendEmailOptions): Promise<SendEmailResult> {
    return this.provider.send(options);
  }

  async sendPasswordResetOtp(
    email: string,
    otp: string,
    recipientName?: string,
  ): Promise<SendEmailResult> {
    const subject = 'Your Nexoraa CleanSoft Password Reset Code';
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #1976d2; margin-bottom: 16px;">Nexoraa CleanSoft</h2>
        <p>Hello${recipientName ? ` ${recipientName}` : ''},</p>
        <p>We received a request to reset your password. Use the following 6-digit verification code:</p>
        <div style="text-align: center; margin: 24px 0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; padding: 12px 24px; background-color: #f5f5f5; border-radius: 6px; border: 1px dashed #1976d2; color: #1976d2; display: inline-block;">
            ${otp}
          </span>
        </div>
        <p style="color: #666; font-size: 14px;">This code will expire in 10 minutes. If you did not request a password reset, please ignore this email.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
        <p style="color: #999; font-size: 12px;">© ${new Date().getFullYear()} Nexoraa CleanSoft. All rights reserved.</p>
      </div>
    `;
    const textContent = `Your Nexoraa CleanSoft password reset code is: ${otp}. It will expire in 10 minutes. If you did not request this, please ignore.`;

    return this.sendEmail({
      to: [{ email, ...(recipientName ? { name: recipientName } : {}) }],
      subject,
      htmlContent,
      textContent,
      tags: ['password-reset'],
    });
  }
}
