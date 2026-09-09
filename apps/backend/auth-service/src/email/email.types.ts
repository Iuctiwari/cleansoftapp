export interface EmailRecipient {
  email: string;
  name?: string;
}

export interface SendEmailOptions {
  to: EmailRecipient[];
  subject: string;
  htmlContent: string;
  textContent?: string;
  tags?: string[];
}

export interface SendEmailResult {
  success: boolean;
  messageId?: string;
  statusCode?: number;
  error?: string;
}

export interface EmailProvider {
  send(options: SendEmailOptions): Promise<SendEmailResult>;
}

export const EMAIL_PROVIDER = Symbol('EMAIL_PROVIDER');
