import { Injectable, Logger } from '@nestjs/common';
import type { EmailProvider, SendEmailOptions, SendEmailResult } from './email.types';

@Injectable()
export class NoopEmailProvider implements EmailProvider {
  private readonly logger = new Logger(NoopEmailProvider.name);

  send(options: SendEmailOptions): Promise<SendEmailResult> {
    this.logger.log(
      `NoopEmailProvider: mock sending email to ${options.to.map((r) => r.email).join(', ')} with subject: "${options.subject}"`,
    );
    return Promise.resolve({
      success: true,
      messageId: 'noop-mock-message-id',
      statusCode: 200,
    });
  }
}
