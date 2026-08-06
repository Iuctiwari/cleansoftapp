import {
  ArgumentsHost,
  Catch,
  ExceptionFilter,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import type { ServerResponse } from 'node:http';

import { TenantError } from './tenant.errors';

@Catch()
export class TenantExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(TenantExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<ServerResponse>();

    if (exception instanceof TenantError) {
      const body = JSON.stringify({
        error: {
          code: exception.code,
          category: exception.category,
          messageKey: exception.messageKey,
          retryable: exception.retryable,
          fields: exception.fields ?? [],
        },
      });
      response.writeHead(exception.statusCode, { 'Content-Type': 'application/json' });
      response.end(body);
      return;
    }

    if (exception instanceof HttpException) {
      const status = exception.getStatus();
      const body = JSON.stringify(exception.getResponse());
      response.writeHead(status, { 'Content-Type': 'application/json' });
      response.end(body);
      return;
    }

    this.logger.error('Unhandled exception in tenant-service', exception);

    const errorBody = JSON.stringify({
      error: {
        code: 'tenant.internal',
        category: 'internal',
        messageKey: 'errors.internal',
        retryable: false,
        fields: [],
      },
    });
    response.writeHead(HttpStatus.INTERNAL_SERVER_ERROR, { 'Content-Type': 'application/json' });
    response.end(errorBody);
  }
}
