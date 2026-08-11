import { randomUUID } from 'node:crypto';

import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import type { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

import type { ApiSuccessEnvelope, ApiSuccessMeta, PaginatedResult } from './platform.types';
import type { RequestWithPlatformContext } from './platform.request';

@Injectable()
export class CorrelationIdInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<RequestWithPlatformContext>();
    const response = context
      .switchToHttp()
      .getResponse<{ setHeader(name: string, value: string): void }>();
    const correlationId = request.headers['x-correlation-id'];
    const resolvedCorrelationId =
      request.correlationId ??
      (typeof correlationId === 'string' && correlationId.trim().length > 0
        ? correlationId
        : randomUUID());

    request.correlationId = resolvedCorrelationId;
    response.setHeader('X-Correlation-ID', resolvedCorrelationId);

    return next.handle();
  }
}

function isPaginatedResult(value: unknown): value is PaginatedResult<unknown> {
  if (typeof value !== 'object' || value === null) {
    return false;
  }

  const candidate = value as Partial<PaginatedResult<unknown>>;
  return (
    Array.isArray(candidate.items) &&
    typeof candidate.page === 'number' &&
    typeof candidate.pageSize === 'number' &&
    typeof candidate.total === 'number'
  );
}

@Injectable()
export class ResponseEnvelopeInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiSuccessEnvelope<unknown>> {
    const request = context.switchToHttp().getRequest<RequestWithPlatformContext>();

    return next.handle().pipe(
      map((value: unknown) => {
        const meta: ApiSuccessMeta = {
          correlationId: request.correlationId ?? randomUUID(),
        };

        if (isPaginatedResult(value)) {
          return {
            data: value.items,
            meta: {
              ...meta,
              page: value.page,
              pageSize: value.pageSize,
              total: value.total,
            },
          };
        }

        return {
          data: value,
          meta,
        };
      }),
    );
  }
}
