/** Minimal structured logger — avoids pulling in @nestjs/common for one class. */
type LogLevel = 'LOG' | 'WARN' | 'ERROR';

function write(level: LogLevel, context: string, message: string): void {
  const line = `[KeepAlive] ${new Date().toISOString()} ${level.padEnd(5)} [${context}] ${message}`;
  if (level === 'ERROR') {
    console.error(line);
  } else if (level === 'WARN') {
    console.warn(line);
  } else {
    console.log(line);
  }
}

export const logger = {
  log: (context: string, message: string): void => write('LOG', context, message),
  warn: (context: string, message: string): void => write('WARN', context, message),
  error: (context: string, message: string): void => write('ERROR', context, message),
};
