import { randomUUID } from 'node:crypto';

import { Inject, Injectable, Logger, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

import { FirebaseIdTokenVerifier, FirebaseTokenError } from './firebase-id-token.verifier';
import { EmailService } from '../email/email.service';
import { PlatformError } from '../platform/platform.errors';
import type { ContractVersion, TrustedContext } from '../platform/platform.types';
import { generateOtp, hashOpaqueSecret, hashPassword, maskDestination } from './auth.crypto';
import { normalizeIdentifier, normalizeIndianMobile } from './auth.normalization';
import { assertStrongPassword } from './auth.service';
import { AUTH_REPOSITORY, type AuthRepository, type ConsumerAccountRecord } from './auth.types';

/** Minimum gap between two verification emails for one account. */
export const CONSUMER_RESEND_COOLDOWN_SECONDS = 60;

const CONTRACT_VERSION: ContractVersion = { major: 1, minor: 0 };

export interface ConsumerRegisterInput {
  readonly fullName: string;
  readonly email: string;
  readonly mobileNumber: string;
  readonly password: string;
}

export interface ConsumerVerificationSent {
  readonly accepted: true;
  readonly contractVersion: ContractVersion;
  readonly deliveryHint: string;
  readonly resendAvailableInSeconds: number;
}

export interface ConsumerProfile {
  readonly actorId: string;
  readonly kind: 'consumer';
  readonly displayName: string;
  readonly email: string;
  readonly mobileNumber: string;
}

function isDuplicateKeyError(error: unknown): boolean {
  return (error as { code?: number } | null)?.code === 11000;
}

/**
 * Sign-up and email verification for marketplace customers. Login, refresh,
 * logout and password reset reuse AuthService with context "consumer".
 */
@Injectable()
export class ConsumerAuthService {
  private readonly logger = new Logger(ConsumerAuthService.name);
  private readonly otpSecret: string;
  private readonly otpTtlSeconds: number;
  private readonly otpMaxAttempts: number;

  constructor(
    @Inject(AUTH_REPOSITORY) private readonly authRepository: AuthRepository,
    configService: ConfigService,
    @Optional() private readonly emailService?: EmailService,
    @Optional() private readonly phoneVerifier?: FirebaseIdTokenVerifier,
  ) {
    this.otpSecret = configService.getOrThrow<string>('AUTH_REFRESH_TOKEN_SECRET');
    this.otpTtlSeconds = Number(configService.getOrThrow<string>('AUTH_OTP_TTL_SECONDS'));
    this.otpMaxAttempts = Number(configService.getOrThrow<string>('AUTH_OTP_MAX_ATTEMPTS'));
  }

  async register(input: ConsumerRegisterInput): Promise<ConsumerVerificationSent> {
    const email = normalizeIdentifier(input.email);
    const fullName = input.fullName.trim().replace(/\s+/g, ' ');
    const mobileNumber = normalizeIndianMobile(input.mobileNumber);
    if (!mobileNumber) {
      throw new PlatformError({
        code: 'consumer.mobile_invalid',
        category: 'validation',
        messageKey: 'errors.consumer.mobile_invalid',
        fields: [{ field: 'mobileNumber', code: 'consumer.mobile_invalid' }],
      });
    }
    if (fullName.length < 2) {
      throw new PlatformError({
        code: 'consumer.name_invalid',
        category: 'validation',
        messageKey: 'errors.consumer.name_invalid',
        fields: [{ field: 'fullName', code: 'consumer.name_invalid' }],
      });
    }
    assertStrongPassword(input.password);

    const byEmail = await this.authRepository.findConsumerAccount({ email });
    if (byEmail?.emailVerified) {
      throw this.conflict('consumer.email_taken', 'email');
    }
    const byMobile = await this.authRepository.findConsumerAccount({ mobileNumber });
    if (byMobile && byMobile.userId !== byEmail?.userId) {
      throw this.conflict('consumer.mobile_taken', 'mobileNumber');
    }

    // An unverified account with this email is a retried sign-up: the new
    // details replace the old ones and a fresh code is sent.
    const now = new Date().toISOString();
    const account: ConsumerAccountRecord = {
      userId: byEmail?.userId ?? `consumer-${randomUUID()}`,
      email,
      mobileNumber,
      displayName: fullName,
      passwordHash: hashPassword(input.password),
      status: 'active',
      emailVerified: false,
      verificationAttempts: 0,
      accessVersion: byEmail?.accessVersion ?? 1,
      passwordChangedAtUtc: now,
      createdAtUtc: byEmail?.createdAtUtc ?? now,
      updatedAtUtc: now,
    };

    try {
      return await this.issueVerificationCode(account);
    } catch (error) {
      if (isDuplicateKeyError(error)) {
        // Lost a race with a concurrent sign-up for the same email or mobile.
        throw this.conflict('consumer.account_exists', 'email');
      }
      throw error;
    }
  }

  async verifyEmail(input: { readonly email: string; readonly otp: string }) {
    const account = await this.authRepository.findConsumerAccount({
      email: normalizeIdentifier(input.email),
    });
    if (account?.emailVerified) {
      return { accepted: true as const, contractVersion: CONTRACT_VERSION };
    }
    if (
      !account?.verificationOtpHash ||
      !account.verificationExpiresAtUtc ||
      account.verificationExpiresAtUtc <= new Date().toISOString()
    ) {
      throw this.invalidCode();
    }
    if (account.verificationAttempts >= this.otpMaxAttempts) {
      throw new PlatformError({
        code: 'consumer.verification_attempts_exceeded',
        category: 'rate_limit',
        messageKey: 'errors.consumer.verification_attempts_exceeded',
      });
    }

    if (hashOpaqueSecret(input.otp, this.otpSecret) !== account.verificationOtpHash) {
      await this.authRepository.saveConsumerAccount({
        ...account,
        verificationAttempts: account.verificationAttempts + 1,
        updatedAtUtc: new Date().toISOString(),
      });
      throw this.invalidCode();
    }

    const now = new Date().toISOString();
    await this.authRepository.saveConsumerAccount({
      ...account,
      emailVerified: true,
      emailVerifiedAtUtc: now,
      verificationOtpHash: undefined,
      verificationExpiresAtUtc: undefined,
      verificationAttempts: 0,
      updatedAtUtc: now,
    });
    return { accepted: true as const, contractVersion: CONTRACT_VERSION };
  }

  /**
   * Verifies the account with a phone code instead of the emailed one. The phone proves its
   * number to Firebase; here we check Firebase's token and that the number is the one on the account.
   */
  async verifyPhone(input: { readonly email: string; readonly idToken: string }) {
    if (!this.phoneVerifier?.isEnabled()) {
      throw new PlatformError({
        code: 'consumer.phone_verification_unavailable',
        category: 'dependency_unavailable',
        messageKey: 'errors.consumer.phone_verification_unavailable',
      });
    }
    const account = await this.authRepository.findConsumerAccount({
      email: normalizeIdentifier(input.email),
    });
    if (account?.emailVerified) {
      return { accepted: true as const, contractVersion: CONTRACT_VERSION };
    }

    let verified: { phoneNumber: string };
    try {
      verified = await this.phoneVerifier.verify(input.idToken);
    } catch (error) {
      this.logger.warn(`Phone token refused: ${error instanceof FirebaseTokenError ? error.reason : String(error)}`);
      throw this.invalidCode();
    }
    // Same neutral answer for "no such account" and "different number": nothing to enumerate.
    const sameNumber =
      account !== null &&
      account !== undefined &&
      verified.phoneNumber.replace(/\D/g, '').slice(-10) === account.mobileNumber.replace(/\D/g, '').slice(-10);
    if (!account || !sameNumber) throw this.invalidCode();

    const now = new Date().toISOString();
    await this.authRepository.saveConsumerAccount({
      ...account,
      emailVerified: true,
      emailVerifiedAtUtc: now,
      phoneVerifiedAtUtc: now,
      verificationOtpHash: undefined,
      verificationExpiresAtUtc: undefined,
      verificationAttempts: 0,
      updatedAtUtc: now,
    });
    return { accepted: true as const, contractVersion: CONTRACT_VERSION };
  }

  /** Neutral answer whether or not the email has an account, to avoid enumeration. */
  async resendVerification(input: { readonly email: string }): Promise<ConsumerVerificationSent> {
    const email = normalizeIdentifier(input.email);
    const neutral: ConsumerVerificationSent = {
      accepted: true,
      contractVersion: CONTRACT_VERSION,
      deliveryHint: 'If this email has an unverified account, a new code has been sent.',
      resendAvailableInSeconds: CONSUMER_RESEND_COOLDOWN_SECONDS,
    };
    const account = await this.authRepository.findConsumerAccount({ email });
    if (!account || account.emailVerified || account.status !== 'active') {
      return neutral;
    }

    const waitSeconds = this.secondsUntilResendAllowed(account);
    if (waitSeconds > 0) {
      return { ...neutral, resendAvailableInSeconds: waitSeconds };
    }

    await this.issueVerificationCode(account);
    return neutral;
  }

  async profile(context: TrustedContext | undefined): Promise<ConsumerProfile> {
    if (!context) {
      throw new PlatformError({
        code: 'platform.unauthenticated',
        category: 'unauthenticated',
        messageKey: 'errors.unauthenticated',
      });
    }
    if (context.kind !== 'consumer') {
      throw new PlatformError({
        code: 'auth.consumer_context_required',
        category: 'forbidden',
        messageKey: 'errors.auth.consumer_context_required',
      });
    }

    const account = await this.authRepository.findConsumerAccount({ userId: context.actorId });
    if (
      !account ||
      account.status !== 'active' ||
      !account.emailVerified ||
      account.accessVersion !== context.accessVersion
    ) {
      throw new PlatformError({
        code: 'auth.session_expired',
        category: 'unauthenticated',
        messageKey: 'errors.auth.session_expired',
      });
    }

    return {
      actorId: account.userId,
      kind: 'consumer',
      displayName: account.displayName,
      email: account.email,
      mobileNumber: account.mobileNumber,
    };
  }

  private async issueVerificationCode(
    account: ConsumerAccountRecord,
  ): Promise<ConsumerVerificationSent> {
    const now = new Date();
    const otp = generateOtp();
    const pending: ConsumerAccountRecord = {
      ...account,
      verificationOtpHash: hashOpaqueSecret(otp, this.otpSecret),
      verificationExpiresAtUtc: new Date(now.getTime() + this.otpTtlSeconds * 1000).toISOString(),
      verificationAttempts: 0,
      verificationSentAtUtc: now.toISOString(),
      updatedAtUtc: now.toISOString(),
    };
    await this.authRepository.saveConsumerAccount(pending);

    if (!this.emailService) {
      this.logger.warn('No email service configured — consumer verification code not delivered');
    } else {
      const result = await this.emailService.sendEmailVerificationOtp(
        account.email,
        otp,
        account.displayName,
      );
      if (!result.success) {
        throw new PlatformError({
          code: 'auth.email_delivery_failed',
          category: 'dependency_unavailable',
          messageKey: 'errors.auth.email_delivery_failed',
          retryable: true,
        });
      }
    }

    return {
      accepted: true,
      contractVersion: CONTRACT_VERSION,
      deliveryHint: `We sent a 6-digit code to ${maskDestination(account.email)}.`,
      resendAvailableInSeconds: CONSUMER_RESEND_COOLDOWN_SECONDS,
    };
  }

  private secondsUntilResendAllowed(account: ConsumerAccountRecord): number {
    if (!account.verificationSentAtUtc) return 0;
    const elapsed = (Date.now() - Date.parse(account.verificationSentAtUtc)) / 1000;
    return Math.max(0, Math.ceil(CONSUMER_RESEND_COOLDOWN_SECONDS - elapsed));
  }

  private conflict(code: string, field: string): PlatformError {
    return new PlatformError({
      code,
      category: 'conflict',
      messageKey: `errors.${code}`,
      fields: [{ field, code }],
    });
  }

  private invalidCode(): PlatformError {
    return new PlatformError({
      code: 'consumer.verification_invalid',
      category: 'validation',
      messageKey: 'errors.consumer.verification_invalid',
    });
  }
}
