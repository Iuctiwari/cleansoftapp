import { ArgumentsHost, Catch, Injectable, type ExceptionFilter } from '@nestjs/common';
import { HttpAdapterHost } from '@nestjs/core';

import { createStandardErrorResponse, getExceptionRequestContext } from './exception.utils';
import type { ExceptionRequest } from './exception.types';

@Catch()
@Injectable()
export class GlobalExceptionFilter implements ExceptionFilter {
  constructor(private readonly adapterHost: HttpAdapterHost) {}

  catch(exception: unknown, host: ArgumentsHost): void {
    const httpContext = host.switchToHttp();
    const request = httpContext.getRequest<ExceptionRequest>();
    const response = httpContext.getResponse<unknown>();
    const body = createStandardErrorResponse(exception, getExceptionRequestContext(request));

    this.adapterHost.httpAdapter.reply(response, body, body.statusCode);
  }
}
