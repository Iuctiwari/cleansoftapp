import { Injectable, Logger } from '@nestjs/common';
import type { EmailProvider, SendEmailOptions, SendEmailResult } from './email.types';

@Injectable()
export class NoopEmailProvider implements EmailProvider {
  private readonly logger = new Logger(NoopEmailProvider.name);

  async send(options: SendEmailOptions): Promise<SendEmailResult> {
  send(options: SendEmailOptions): Promise<SendEmailResult> {
    this.logger.log(
      `NoopEmailProvider: mock sending email to ${options.to.map((r) => r.email).join(', ')} with subject: "${options.subject}"`,
    );
    return {
    return Promise.resolve({
      success: true,
      messageId: 'noop-mock-message-id',
      statusCode: 200,
    };
    });
  }
}
