// PM2 process list for the single-EC2 deployment. Each service runs its built
// dist/main.js directly (same as Render's start:prod) with two env files:
//   ~/nexoraa-env/common.env      — shared secrets + internal localhost URLs
//   ~/nexoraa-env/<service>.env   — that service's own values (wins on conflict)
// PORT is set here, so it always matches services.cjs and the Caddy config.
const os = require('node:os');
const path = require('node:path');

const { SERVICES } = require('./services.cjs');

const ROOT = path.resolve(__dirname, '../..');
const ENV_DIR = process.env.NEXORAA_ENV_DIR || path.join(os.homedir(), 'nexoraa-env');

module.exports = {
  apps: SERVICES.map(({ name, port }) => ({
    name,
    cwd: path.join(ROOT, 'apps/backend', name),
    script: 'dist/main.js',
    node_args: [
      `--env-file=${path.join(ENV_DIR, 'common.env')}`,
      `--env-file=${path.join(ENV_DIR, `${name}.env`)}`,
      // Keeps 14 services inside a small instance's RAM.
      '--max-old-space-size=192',
    ],
    env: { NODE_ENV: 'production', PORT: String(port), SERVICE_NAME: name },
    max_memory_restart: '320M',
    exp_backoff_restart_delay: 2000,
    time: true,
  })),
};
