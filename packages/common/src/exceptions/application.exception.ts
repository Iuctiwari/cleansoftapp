import { HttpStatus } from '@nestjs/common';

import { FoundationException, type FoundationExceptionOptions } from '../foundation.exception';
import { EXCEPTION_CODES, EXCEPTION_MESSAGES } from './exception.constants';

export interface ApplicationExceptionOptions extends FoundationExceptionOptions {
  readonly statusCode?: number;
}

export class ApplicationException extends FoundationException {
  readonly statusCode: number;

  constructor(
    message: string,
    code: string = EXCEPTION_CODES.APPLICATION_ERROR,
    options: ApplicationExceptionOptions = {},
  ) {
    super(message, code, options);
    this.statusCode = options.statusCode ?? HttpStatus.INTERNAL_SERVER_ERROR;
  }
}

export class ValidationApplicationException extends ApplicationException {
  constructor(errors: readonly string[], message: string = EXCEPTION_MESSAGES.VALIDATION_ERROR) {
    super(message, EXCEPTION_CODES.VALIDATION_ERROR, {
      details: { errors: [...errors] },
      statusCode: HttpStatus.BAD_REQUEST,
    });
  }
}

export class InternalApplicationException extends ApplicationException {
  constructor(cause?: unknown) {
    super(EXCEPTION_MESSAGES.INTERNAL_SERVER_ERROR, EXCEPTION_CODES.INTERNAL_SERVER_ERROR, {
      cause,
      statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
    });
  }
}
