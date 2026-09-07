import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';

import { BrevoEmailProvider } from './brevo-email.provider';
import { EmailService } from './email.service';
import { EMAIL_PROVIDER } from './email.types';
import { EMAIL_PROVIDER, type EmailProvider } from './email.types';
import { NoopEmailProvider } from './noop-email.provider';

@Module({
  imports: [ConfigModule],
  providers: [
    BrevoEmailProvider,
    NoopEmailProvider,
    {
      provide: EMAIL_PROVIDER,
      useFactory: (
        configService: ConfigService,
        brevo: BrevoEmailProvider,
        noop: NoopEmailProvider,
      ) => {
      ): EmailProvider => {
        const apiKey = configService.get<string>('BREVO_API_KEY')?.trim();
        const nodeEnv = configService.get<string>('NODE_ENV')?.trim();
        if (!apiKey && nodeEnv !== 'production') {
          return noop;
        }
        return brevo;
      },
      inject: [ConfigService, BrevoEmailProvider, NoopEmailProvider],
    },
    EmailService,
  ],
  exports: [EmailService],
})
export class EmailModule {}
