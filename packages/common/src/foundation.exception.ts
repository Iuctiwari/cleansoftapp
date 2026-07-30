export interface FoundationExceptionOptions {
  cause?: unknown;
  details?: Readonly<Record<string, unknown>>;
}

export class FoundationException extends Error {
  readonly code: string;
  readonly details?: Readonly<Record<string, unknown>>;

  constructor(message: string, code: string, options: FoundationExceptionOptions = {}) {
    super(message, { cause: options.cause });
    this.name = new.target.name;
    this.code = code;
    this.details = options.details;
  }
}
