import { createPublicKey, createVerify } from 'node:crypto';

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

const CERTS_URL =
  'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
const CLOCK_SKEW_SECONDS = 120;

export interface FirebasePhoneClaims {
  /** Firebase user id for this phone number. */
  readonly uid: string;
  /** E.164, e.g. +919811200001. */
  readonly phoneNumber: string;
}

/** Why a Firebase token was refused: machine-readable, safe to show as a generic failure. */
export class FirebaseTokenError extends Error {
  constructor(readonly reason: string) {
    super(reason);
  }
}

/**
 * Checks the ID token the phone gets from Firebase after the person types the SMS code
 * (or the fixed code of a Firebase test number). Pure crypto against Google's public
 * certificates: no Firebase SDK and no secret key needed. Switched off until
 * FIREBASE_PROJECT_ID is set.
 */
@Injectable()
export class FirebaseIdTokenVerifier {
  private readonly logger = new Logger(FirebaseIdTokenVerifier.name);
  private readonly projectId: string | undefined;
  private cache: { readonly certs: Record<string, string>; readonly expiresAt: number } | undefined;

  constructor(configService: ConfigService) {
    this.projectId = configService.get<string>('FIREBASE_PROJECT_ID') || undefined;
  }

  isEnabled(): boolean {
    return Boolean(this.projectId);
  }

  async verify(idToken: string, nowSeconds = Math.floor(Date.now() / 1000)): Promise<FirebasePhoneClaims> {
    const projectId = this.projectId;
    if (!projectId) throw new FirebaseTokenError('not_configured');
    const parts = idToken.split('.');
    if (parts.length !== 3) throw new FirebaseTokenError('malformed');
    const [header64, payload64, signature64] = parts as [string, string, string];

    let header: { alg?: string; kid?: string };
    let payload: Record<string, unknown>;
    try {
      header = JSON.parse(Buffer.from(header64, 'base64url').toString('utf8'));
      payload = JSON.parse(Buffer.from(payload64, 'base64url').toString('utf8'));
    } catch {
      throw new FirebaseTokenError('malformed');
    }
    if (header.alg !== 'RS256' || !header.kid) throw new FirebaseTokenError('bad_header');

    const certificate = (await this.certs())[header.kid];
    if (!certificate) throw new FirebaseTokenError('unknown_key');
    const signatureOk = createVerify('RSA-SHA256')
      .update(`${header64}.${payload64}`)
      .verify(createPublicKey(certificate), Buffer.from(signature64, 'base64url'));
    if (!signatureOk) throw new FirebaseTokenError('bad_signature');

    const exp = Number(payload.exp);
    const iat = Number(payload.iat);
    if (!(exp > nowSeconds - CLOCK_SKEW_SECONDS)) throw new FirebaseTokenError('expired');
    if (!(iat <= nowSeconds + CLOCK_SKEW_SECONDS)) throw new FirebaseTokenError('issued_in_future');
    if (payload.aud !== projectId) throw new FirebaseTokenError('wrong_audience');
    if (payload.iss !== `https://securetoken.google.com/${projectId}`) {
      throw new FirebaseTokenError('wrong_issuer');
    }
    if (typeof payload.sub !== 'string' || payload.sub.length === 0) {
      throw new FirebaseTokenError('no_subject');
    }
    if (typeof payload.phone_number !== 'string' || !payload.phone_number.startsWith('+')) {
      throw new FirebaseTokenError('not_a_phone_login');
    }
    return { uid: payload.sub, phoneNumber: payload.phone_number };
  }

  /** Google's signing certificates, cached for as long as Google says. */
  protected async certs(): Promise<Record<string, string>> {
    if (this.cache && this.cache.expiresAt > Date.now()) return this.cache.certs;
    const response = await fetch(CERTS_URL, { signal: AbortSignal.timeout(8_000) });
    if (!response.ok) {
      this.logger.warn(`Could not load Firebase certificates: HTTP ${response.status}`);
      throw new FirebaseTokenError('certs_unavailable');
    }
    const maxAge = /max-age=(\d+)/.exec(response.headers.get('cache-control') ?? '')?.[1];
    const certs = (await response.json()) as Record<string, string>;
    this.cache = { certs, expiresAt: Date.now() + Number(maxAge ?? 3600) * 1000 };
    return certs;
  }
}
