import { createServer, type Server } from 'node:http';

import type { SchedulerStatus } from './scheduler';

/**
 * The smallest possible HTTP server. It exists for two reasons:
 *  1. Render's free tier only allows Web Services (not Background Workers
 *     or Cron Jobs — both require a paid plan), and a Web Service must bind
 *     to $PORT and respond to requests.
 *  2. `GET /` is also this process's own self-ping target (see main.ts) —
 *     without inbound traffic, Render would spin this service itself down
 *     after 15 minutes idle, same as any other free web service, which
 *     would silently stop all the pinging.
 *
 * `GET /status` returns the last ping round as JSON for manual verification.
 */
export function createHttpServer(getStatus: () => SchedulerStatus): Server {
  return createServer((req, res) => {
    if (req.url === '/status') {
      const body = JSON.stringify(getStatus(), null, 2);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(body);
      return;
    }

    res.writeHead(200, { 'Content-Type': 'text/plain' });
    res.end('ok');
  });
}
