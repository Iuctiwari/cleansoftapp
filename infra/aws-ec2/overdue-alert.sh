#!/usr/bin/env bash
# Daily "orders running late" push to each shop's owners.
#
#   bash infra/aws-ec2/overdue-alert.sh                 # run now
#   bash infra/aws-ec2/overdue-alert.sh --install-cron # every day 09:00 IST
set -euo pipefail

SCRIPT="$(readlink -f "$0")"
ENV_DIR="${NEXORAA_ENV_DIR:-$HOME/nexoraa-env}"

if [ "${1:-}" = "--install-cron" ]; then
  mkdir -p "$HOME/deploy-logs"
  # 03:30 UTC = 09:00 IST
  echo "30 3 * * * $USER bash $SCRIPT >> $HOME/deploy-logs/overdue-alert.log 2>&1" \
    | sudo tee /etc/cron.d/nexoraa-overdue-alert >/dev/null
  sudo chmod 644 /etc/cron.d/nexoraa-overdue-alert
  echo "Daily overdue alert scheduled (09:00 IST). Running one now to check it works..."
  exec bash "$SCRIPT"
fi

SECRET="$(grep -h '^INTERNAL_SERVICE_SECRET=' "$ENV_DIR"/common.env | head -1 | cut -d= -f2-)"
[ -n "$SECRET" ] || { echo "INTERNAL_SERVICE_SECRET missing in $ENV_DIR/common.env"; exit 1; }
echo "$(date -u +%FT%TZ) overdue alert: $(curl -fsS -m 60 -X POST \
  -H "x-internal-secret: $SECRET" http://127.0.0.1:3007/api/v1/internal/overdue-alerts)"
