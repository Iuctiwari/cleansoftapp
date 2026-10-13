import { randomUUID } from 'node:crypto';

import { GetObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { Injectable, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export const PHOTO_CONTENT_TYPE = 'image/jpeg';
export const MAX_PICKUP_PHOTOS = 6;
const UPLOAD_LINK_SECONDS = 10 * 60;
const VIEW_LINK_SECONDS = 60 * 60;

/** A pickup photo's S3 key: pickups/<tenant>/<request>/<uuid>.jpg */
const KEY_SHAPE = /^pickups\/[A-Za-z0-9-]+\/[A-Za-z0-9-]+\/[0-9a-f-]{36}\.jpg$/;

export interface PhotoUploadSlot {
  readonly key: string;
  readonly uploadUrl: string;
  readonly contentType: string;
}

/**
 * Private S3 bucket for the photos a worker takes at pickup. The phone uploads
 * with a short-lived signed link and the customer views through another one, so
 * nothing in the bucket is ever public. Credentials come from the server's IAM
 * role. Switched off (503) until PICKUP_PHOTOS_BUCKET is set.
 */
@Injectable()
export class PhotoStorage {
  private client?: S3Client;

  constructor(private readonly configService: ConfigService) {}

  private get bucket(): string | undefined {
    return this.configService.get<string>('PICKUP_PHOTOS_BUCKET') || undefined;
  }

  isEnabled(): boolean {
    return Boolean(this.bucket);
  }

  prefixFor(tenantId: string, requestId: string): string {
    return `pickups/${tenantId}/${requestId}/`;
  }

  /** True when the key is a photo slot we issued for exactly this request. */
  isKeyFor(key: string, tenantId: string, requestId: string): boolean {
    return key.startsWith(this.prefixFor(tenantId, requestId)) && KEY_SHAPE.test(key);
  }

  async createUploadSlots(
    tenantId: string,
    requestId: string,
    count: number,
  ): Promise<PhotoUploadSlot[]> {
    const { client, bucket } = this.require();
    return Promise.all(
      Array.from({ length: count }, async () => {
        const key = `${this.prefixFor(tenantId, requestId)}${randomUUID()}.jpg`;
        const uploadUrl = await getSignedUrl(
          client,
          new PutObjectCommand({ Bucket: bucket, Key: key, ContentType: PHOTO_CONTENT_TYPE }),
          { expiresIn: UPLOAD_LINK_SECONDS },
        );
        return { key, uploadUrl, contentType: PHOTO_CONTENT_TYPE };
      }),
    );
  }

  /** A temporary link to look at one photo; undefined when storage is off. */
  async viewUrl(key: string): Promise<string | undefined> {
    if (!this.isEnabled()) return undefined;
    const { client, bucket } = this.require();
    return getSignedUrl(client, new GetObjectCommand({ Bucket: bucket, Key: key }), {
      expiresIn: VIEW_LINK_SECONDS,
    });
  }

  private require(): { client: S3Client; bucket: string } {
    const bucket = this.bucket;
    if (!bucket) throw new ServiceUnavailableException('Photo storage is not set up yet');
    this.client ??= new S3Client({
      region: this.configService.get<string>('AWS_REGION', 'ap-south-1'),
    });
    return { client: this.client, bucket };
  }
}
