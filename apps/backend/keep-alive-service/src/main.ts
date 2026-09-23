import { loadConfig } from './config';
import { loadDotEnvIfPresent } from './env-file';
import { createHttpServer } from './http-server';
import { logger } from './logger';
import { KeepAliveScheduler } from './scheduler';

function bootstrap(): void {
  loadDotEnvIfPresent();
  const config = loadConfig();

  const targets = [...config.targets];
  if (config.selfUrl !== undefined) {
    // Self-ping: Render's free-tier inactivity timer only resets on inbound
    // HTTP traffic, not on this process's own internal activity — without
    // this, the keep-alive service would eventually go to sleep itself.
    targets.push({ name: 'keep-alive-service (self)', url: `${config.selfUrl}/` });
  } else {
    logger.warn(
      'Bootstrap',
      'RENDER_EXTERNAL_URL is not set — self-ping disabled. ' +
        'On Render this is provided automatically at runtime; running elsewhere this service may itself go idle.',
    );
  }

  const scheduler = new KeepAliveScheduler(
    targets,
    config.intervalMs,
    config.requestTimeoutMs,
    config.concurrency,
  );
  const server = createHttpServer(() => scheduler.getStatus());

  server.listen(config.port, config.host, () => {
    logger.log('Bootstrap', `Listening on http://${config.host}:${config.port}`);
    scheduler.start();
  });

  const shutdown = (signal: string): void => {
    logger.log('Bootstrap', `${signal} received — shutting down.`);
    scheduler.stop();
    server.close(() => process.exit(0));
  };
  process.on('SIGTERM', () => shutdown('SIGTERM'));
  process.on('SIGINT', () => shutdown('SIGINT'));

  // Last line of defense: log and keep running rather than let one bad
  // promise or synchronous throw take the whole ping loop down.
  process.on('unhandledRejection', (reason) => {
    logger.error('Process', `Unhandled rejection: ${String(reason)}`);
  });
  process.on('uncaughtException', (error) => {
    logger.error('Process', `Uncaught exception: ${error.message}`);
  });
}

bootstrap();
