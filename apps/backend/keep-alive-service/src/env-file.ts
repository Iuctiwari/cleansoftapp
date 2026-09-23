import { existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * Minimal local `.env` loader — avoids adding a `dotenv` dependency for
 * something this small (same approach already used elsewhere in this repo,
 * e.g. platform-admin-service/scripts/seed-local-admin.js).
 *
 * A no-op in production: Render injects real environment variables
 * directly, and no `.env` file is deployed alongside the code.
 */
export function loadDotEnvIfPresent(): void {
  const envPath = join(__dirname, '..', '.env');
  if (!existsSync(envPath)) return;

  for (const line of readFileSync(envPath, 'utf8').split('\n')) {
    const match = /^([A-Z0-9_]+)=(.*)$/.exec(line.trim());
    if (match !== null && !(match[1] in process.env)) {
      process.env[match[1]] = match[2];
    }
  }
}
