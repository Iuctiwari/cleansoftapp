import { ArgumentsHost, Catch, ExceptionFilter, Logger } from '@nestjs/common';

import { toPlatformError } from './platform.errors';
import type { ApiErrorEnvelope } from './platform.types';
import type { RequestWithPlatformContext } from './platform.request';

interface ErrorResponse {
  status(code: number): ErrorResponse;
  json(body: ApiErrorEnvelope): void;
}

@Catch()
export class PlatformExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PlatformExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost): void {
    const http = host.switchToHttp();
    const request = http.getRequest<RequestWithPlatformContext>();
    const response = http.getResponse<ErrorResponse>();
    const error = toPlatformError(exception);
    const correlationId = request.correlationId ?? 'missing-correlation-id';

    if (error.category === 'internal') {
      this.logger.error(`Internal error ${correlationId}:`, exception);
    } else {
      this.logger.error(`${error.code} (${correlationId})`);
    }

    response.status(error.statusCode).json({
      error: {
        ...error.toPublicDetails(),
        correlationId,
      },
    });
  }
}
