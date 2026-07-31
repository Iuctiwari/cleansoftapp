import type { IncomingMessage, ServerResponse } from 'node:http';

import { Injectable, type NestMiddleware } from '@nestjs/common';

import { resolveCorrelationId } from './correlation-id';
import { CORRELATION_ID_HEADER, REQUEST_ID_HEADER } from './logger.constants';

@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  use(request: IncomingMessage, response: ServerResponse, next: () => void): void {
    const correlationId = resolveCorrelationId(request.headers);
    request.id = correlationId;
    request.headers[CORRELATION_ID_HEADER] = correlationId;
    request.headers[REQUEST_ID_HEADER] = correlationId;
    response.setHeader(CORRELATION_ID_HEADER, correlationId);
    response.setHeader(REQUEST_ID_HEADER, correlationId);
    next();
  }
}
