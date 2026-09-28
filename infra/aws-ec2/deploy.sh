#!/usr/bin/env bash
# Build and (re)start every backend service, then (re)configure HTTPS.
# Run for the first deploy and after every code change:
#   bash infra/aws-ec2/deploy.sh            # pulls latest code first
#   bash infra/aws-ec2/deploy.sh --no-pull  # deploy what is checked out
# Optional: put PUBLIC_DOMAIN=api.example.com in ~/nexoraa-env/deploy.conf to use
# your own domain; otherwise <public-ip>.sslip.io is used automatically.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_DIR="${NEXORAA_ENV_DIR:-$HOME/nexoraa-env}"
# Let corepack fetch the repo's pinned pnpm version without asking.
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
cd "$ROOT"

SERVICES="$(node "$SCRIPT_DIR/services.cjs" names)"

echo "==> Checking env files"
missing=0
for file in common $SERVICES; do
  if [ ! -f "$ENV_DIR/$file.env" ]; then
    echo "   MISSING: $ENV_DIR/$file.env"; missing=1
  elif grep -q 'FILL_ME' "$ENV_DIR/$file.env"; then
    echo "   NOT FILLED IN: $ENV_DIR/$file.env ($(grep -c 'FILL_ME' "$ENV_DIR/$file.env") value(s))"; missing=1
  fi
done
[ "$missing" -eq 0 ] || { echo "Fix the env files above, then re-run."; exit 1; }

if [ "${1:-}" != "--no-pull" ]; then
  echo "==> Pulling latest code"
  git pull --ff-only
fi

echo "==> Installing dependencies"
corepack pnpm install --frozen-lockfile

echo "==> Building (one at a time to fit in memory — takes a while)"
filters=""
for s in $SERVICES; do filters="$filters --filter=@nexoraa/$s"; done
# shellcheck disable=SC2086
NODE_OPTIONS=--max-old-space-size=1536 corepack pnpm turbo run build --concurrency=1 $filters

echo "==> Starting services"
pm2 startOrReload "$SCRIPT_DIR/ecosystem.config.cjs" --update-env
pm2 save

echo "==> Configuring HTTPS"
[ -f "$ENV_DIR/deploy.conf" ] && . "$ENV_DIR/deploy.conf"
if [ -z "${PUBLIC_DOMAIN:-}" ]; then
  token="$(curl -fsS -X PUT http://169.254.169.254/latest/api/token -H 'X-aws-ec2-metadata-token-ttl-seconds: 60')"
  public_ip="$(curl -fsS -H "X-aws-ec2-metadata-token: $token" http://169.254.169.254/latest/meta-data/public-ipv4)"
  PUBLIC_DOMAIN="${public_ip//./-}.sslip.io"
fi
node "$SCRIPT_DIR/services.cjs" caddyfile "$PUBLIC_DOMAIN" | sudo tee /etc/caddy/Caddyfile >/dev/null
sudo systemctl reload caddy || sudo systemctl restart caddy

sleep 5
pm2 status

cat <<EOF

Deployed. Public base domain: $PUBLIC_DOMAIN
(HTTPS certificates are issued on the first request to each URL; allow ~1 minute.)

Put these lines in apps/mobile-app/.env, then rebuild the APK:
$(node "$SCRIPT_DIR/services.cjs" mobile-env "$PUBLIC_DOMAIN")
EOF
