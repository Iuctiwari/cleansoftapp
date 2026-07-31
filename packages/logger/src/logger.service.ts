import {
  Injectable,
  type LoggerService as NestLoggerService,
  type OnApplicationShutdown,
} from '@nestjs/common';
import { PinoLogger } from 'nestjs-pino';

@Injectable()
export class LoggerService implements NestLoggerService, OnApplicationShutdown {
  constructor(private readonly logger: PinoLogger) {}

  log(message: unknown, ...optionalParams: unknown[]): void {
    this.logger.info(this.bindings(message, optionalParams), this.message(message));
  }

  error(message: unknown, ...optionalParams: unknown[]): void {
    this.logger.error(this.bindings(message, optionalParams), this.message(message));
  }

  warn(message: unknown, ...optionalParams: unknown[]): void {
    this.logger.warn(this.bindings(message, optionalParams), this.message(message));
  }

  debug(message: unknown, ...optionalParams: unknown[]): void {
    this.logger.debug(this.bindings(message, optionalParams), this.message(message));
  }

  verbose(message: unknown, ...optionalParams: unknown[]): void {
    this.logger.trace(this.bindings(message, optionalParams), this.message(message));
  }

  fatal(message: unknown, ...optionalParams: unknown[]): void {
    this.logger.fatal(this.bindings(message, optionalParams), this.message(message));
  }

  setContext(context: string): void {
    this.logger.setContext(context);
  }

  flush(): void {
    this.logger.logger.flush();
  }

  onApplicationShutdown(): void {
    this.flush();
  }

  private bindings(message: unknown, optionalParams: unknown[]): Record<string, unknown> {
    const context = this.context(optionalParams);

    if (message instanceof Error) {
      return { context, err: message };
    }

    if (typeof message === 'object' && message !== null && !Array.isArray(message)) {
      return { ...message, context };
    }

    return context ? { context } : {};
  }

  private context(optionalParams: unknown[]): string | undefined {
    const candidate = optionalParams.at(-1);
    return typeof candidate === 'string' ? candidate : undefined;
  }

  private message(value: unknown): string {
    if (value instanceof Error) {
      return value.message;
    }

    return typeof value === 'string' ? value : 'application log';
  }
}
