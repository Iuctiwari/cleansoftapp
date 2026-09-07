import { ConfigService } from '@nestjs/config';
import { BrevoEmailProvider } from '../src/email/brevo-email.provider';
import { EmailService } from '../src/email/email.service';
import type { EmailProvider } from '../src/email/email.types';
import type { EmailProvider, SendEmailOptions, SendEmailResult } from '../src/email/email.types';

describe('BrevoEmailProvider', () => {
  const originalFetch = globalThis.fetch;

  afterEach(() => {
    globalThis.fetch = originalFetch;
    jest.restoreAllMocks();
  });

  function createProvider(apiKey = 'test-api-key'): BrevoEmailProvider {
    const configService = {
      get: (key: string) => {
      get: (key: string): string | undefined => {
        if (key === 'BREVO_API_KEY') return apiKey;
        if (key === 'BREVO_SENDER_EMAIL') return 'noreply@nexoraa.com';
        if (key === 'BREVO_SENDER_NAME') return 'Nexoraa CleanSoft';
        return undefined;
      },
    } as unknown as ConfigService;

    return new BrevoEmailProvider(configService);
  }

  it('fails gracefully when BREVO_API_KEY is not configured', async () => {
    const provider = createProvider('');
    const result = await provider.send({
      to: [{ email: 'test@example.com' }],
      subject: 'Test Subject',
      htmlContent: '<p>Test</p>',
    });

    expect(result.success).toBe(false);
    expect(result.error).toContain('configuration is missing');
  });

  it('sends email successfully via Brevo API', async () => {
    const mockFetch = jest.fn().mockResolvedValue({
      ok: true,
      status: 201,
      json: async () => ({ messageId: '<mock-msg-123@smtp-relay.mailin.fr>' }),
    });
    globalThis.fetch = mockFetch as unknown as typeof fetch;
    const fetchSpy = jest.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ messageId: '<mock-msg-123@smtp-relay.mailin.fr>' }), {
        status: 201,
        headers: { 'Content-Type': 'application/json' },
      }),
    );

    const provider = createProvider('valid-api-key');
    const result = await provider.send({
      to: [{ email: 'user@example.com', name: 'Test User' }],
      subject: 'Reset Code',
      htmlContent: '<p>123456</p>',
      textContent: '123456',
      tags: ['password-reset'],
    });

    expect(result.success).toBe(true);
    expect(result.messageId).toBe('<mock-msg-123@smtp-relay.mailin.fr>');
    expect(mockFetch).toHaveBeenCalledTimes(1);
    const [url, requestInit] = mockFetch.mock.calls[0];
    expect(fetchSpy).toHaveBeenCalledTimes(1);

    const [url, requestInit] = fetchSpy.mock.calls[0];
    expect(url).toBe('https://api.brevo.com/v3/smtp/email');
    expect(requestInit.method).toBe('POST');
    expect(requestInit.headers['api-key']).toBe('valid-api-key');
    expect(requestInit?.method).toBe('POST');

    const body = JSON.parse(requestInit.body);
    const headers = requestInit?.headers as Record<string, string>;
    expect(headers['api-key']).toBe('valid-api-key');

    interface BrevoRequestBody {
      to: Array<{ email: string; name?: string }>;
      sender: { name: string; email: string };
      subject: string;
    }
    const rawBody = typeof requestInit?.body === 'string' ? requestInit.body : '';
    const body = JSON.parse(rawBody) as unknown as BrevoRequestBody;
    expect(body.to).toEqual([{ email: 'user@example.com', name: 'Test User' }]);
    expect(body.sender).toEqual({ name: 'Nexoraa CleanSoft', email: 'noreply@nexoraa.com' });
    expect(body.sender).toEqual({
      name: 'Nexoraa CleanSoft',
      email: 'noreply@nexoraa.com',
    });
    expect(body.subject).toBe('Reset Code');
  });

  it('handles non-200 responses from Brevo API gracefully', async () => {
    const mockFetch = jest.fn().mockResolvedValue({
      ok: false,
      status: 400,
      text: async () => '{"code":"invalid_parameter","message":"Invalid email address"}',
    });
    globalThis.fetch = mockFetch as unknown as typeof fetch;
    jest.spyOn(globalThis, 'fetch').mockResolvedValue(
      new Response(
        JSON.stringify({
          code: 'invalid_parameter',
          message: 'Invalid email address',
        }),
        { status: 400, headers: { 'Content-Type': 'application/json' } },
      ),
    );

    const provider = createProvider('valid-api-key');
    const result = await provider.send({
      to: [{ email: 'bad-email' }],
      subject: 'Test',
      htmlContent: '<p>Test</p>',
    });

    expect(result.success).toBe(false);
    expect(result.statusCode).toBe(400);
    expect(result.error).toContain('Brevo API error (status 400)');
  });

  it('handles network failure during fetch gracefully', async () => {
    const mockFetch = jest.fn().mockRejectedValue(new Error('Connection timed out'));
    globalThis.fetch = mockFetch as unknown as typeof fetch;
    jest.spyOn(globalThis, 'fetch').mockRejectedValue(new Error('Connection timed out'));

    const provider = createProvider('valid-api-key');
    const result = await provider.send({
      to: [{ email: 'user@example.com' }],
      subject: 'Test',
      htmlContent: '<p>Test</p>',
    });

    expect(result.success).toBe(false);
    expect(result.error).toBe('Connection timed out');
  });
});

describe('EmailService', () => {
  it('delegates password reset OTP emails to the injected provider', async () => {
    const sendMock = jest
      .fn<Promise<SendEmailResult>, [SendEmailOptions]>()
      .mockResolvedValue({ success: true, messageId: 'msg-456' });

    const mockProvider: EmailProvider = {
      send: jest.fn().mockResolvedValue({ success: true, messageId: 'msg-456' }),
      send: sendMock,
    };

    const service = new EmailService(mockProvider);
    const result = await service.sendPasswordResetOtp('owner@nexoraa.com', '654321', 'Owner Name');

    expect(result.success).toBe(true);
    expect(mockProvider.send).toHaveBeenCalledTimes(1);
    const options = (mockProvider.send as jest.Mock).mock.calls[0][0];
    expect(sendMock).toHaveBeenCalledTimes(1);
    const options = sendMock.mock.calls[0][0];
    expect(options.to).toEqual([{ email: 'owner@nexoraa.com', name: 'Owner Name' }]);
    expect(options.subject).toBe('Your Nexoraa CleanSoft Password Reset Code');
    expect(options.htmlContent).toContain('654321');
    expect(options.textContent).toContain('654321');
  });
});
