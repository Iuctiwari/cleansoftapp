import { randomUUID } from 'node:crypto';
import type { IncomingHttpHeaders } from 'node:http';

import { CORRELATION_ID_HEADER, REQUEST_ID_HEADER } from './logger.constants';

const VALID_CORRELATION_ID = /^[A-Za-z0-9._:-]{1,128}$/;

interface ClientIpRequest {
  headers?: IncomingHttpHeaders;
  remoteAddress?: string;
  socket?: {
    remoteAddress?: string;
  };
}

function firstHeaderValue(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export function generateCorrelationId(): string {
  return randomUUID();
}

export function normalizeCorrelationId(value: string | string[] | undefined): string | undefined {
  const candidate = firstHeaderValue(value)?.trim();

  return candidate && VALID_CORRELATION_ID.test(candidate) ? candidate : undefined;
}

export function resolveCorrelationId(headers: IncomingHttpHeaders): string {
  return (
    normalizeCorrelationId(headers[CORRELATION_ID_HEADER]) ??
    normalizeCorrelationId(headers[REQUEST_ID_HEADER]) ??
    generateCorrelationId()
  );
}

export function getClientIp(request: ClientIpRequest): string | undefined {
  const forwardedFor = firstHeaderValue(request.headers?.['x-forwarded-for'])
    ?.split(',')[0]
    ?.trim();
  const realIp = firstHeaderValue(request.headers?.['x-real-ip'])?.trim();

  return forwardedFor || realIp || request.socket?.remoteAddress || request.remoteAddress;
}
