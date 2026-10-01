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

  /**
   * Invitation for a staff member added by an owner. The account already exists;
   * the staff member sets their own password via the app's "Forgot password?"
   * OTP flow, so no password is ever sent by email.
   */
  async sendStaffInvitation(input: {
    email: string;
    staffName: string;
    businessName: string;
    loginId: string;
    role: string;
  }): Promise<SendEmailResult> {
    const escape = (value: string) =>
      value.replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`);
    const business = escape(input.businessName);
    const subject = `You're invited to join ${input.businessName} on Nexoraa`;
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 8px;">
        <h2 style="color: #1976d2; margin-bottom: 16px;">Nexoraa CleanSoft</h2>
        <p>Hello ${escape(input.staffName)},</p>
        <p><strong>${business}</strong> has added you to their team on Nexoraa CleanSoft as <strong>${escape(input.role)}</strong>.</p>
        <p>Your login ID is:</p>
        <div style="text-align: center; margin: 16px 0;">
          <span style="font-size: 18px; font-weight: bold; padding: 10px 18px; background-color: #f5f5f5; border-radius: 6px; color: #1976d2; display: inline-block;">${escape(input.loginId)}</span>
        </div>
        <p><strong>To set your password:</strong></p>
        <ol>
          <li>Install and open the Nexoraa CleanSoft app.</li>
          <li>On the login screen, tap <strong>Forgot password?</strong></li>
          <li>Enter <strong>${escape(input.loginId)}</strong> — you'll receive a 6-digit code by email.</li>
          <li>Enter the code, choose your password, and sign in.</li>
        </ol>
        <p style="color: #666; font-size: 14px;">If you weren't expecting this invitation, you can ignore this email.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
        <p style="color: #999; font-size: 12px;">© ${new Date().getFullYear()} Nexoraa CleanSoft. All rights reserved.</p>
      </div>
    `;
    const textContent =
      `${input.businessName} has added you to their team on Nexoraa CleanSoft as ${input.role}. ` +
      `Your login ID is ${input.loginId}. To set your password, open the Nexoraa CleanSoft app, ` +
      `tap "Forgot password?" on the login screen and enter your login ID to receive a code.`;

    return this.sendEmail({
      to: [{ email: input.email, name: input.staffName }],
      subject,
      htmlContent,
      textContent,
      tags: ['staff-invitation'],
    });
  }
}
