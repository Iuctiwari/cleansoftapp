#!/usr/bin/env bash
# Nightly MongoDB backup → private S3 bucket (created by infra/terraform/backups.tf).
#
#   bash infra/aws-ec2/backup-db.sh <bucket> [alert-topic-arn]              # back up now
#   bash infra/aws-ec2/backup-db.sh --install-cron <bucket> [alert-topic-arn] # nightly, 02:00 IST
#
# Every database the services use (from ~/nexoraa-env/*.env MONGODB_URI) is dumped
# to one gzip archive and uploaded as s3://<bucket>/daily/<db>/<UTC time>.archive.gz.
# S3 deletes backups older than the bucket's lifecycle (30 days by default).
# On failure, an alert email is sent through the SNS topic, if given.
#
# Restore (replaces the data in the target database — stop services first):
#   aws s3 cp s3://<bucket>/daily/<db>/<file> - | mongorestore --uri='<uri>' --archive --gzip --drop
set -euo pipefail
export PATH="$PATH:/usr/local/bin:/snap/bin"

SCRIPT="$(readlink -f "$0")"
ENV_DIR="${NEXORAA_ENV_DIR:-$HOME/nexoraa-env}"

if [ "${1:-}" = "--install-cron" ]; then
  BUCKET="${2:?usage: backup-db.sh --install-cron <bucket> [alert-topic-arn]}"
  TOPIC="${3:-}"
  mkdir -p "$HOME/deploy-logs"
  # 20:30 UTC = 02:00 IST
  echo "30 20 * * * $USER bash $SCRIPT $BUCKET $TOPIC >> $HOME/deploy-logs/backup.log 2>&1" \
    | sudo tee /etc/cron.d/nexoraa-db-backup >/dev/null
  sudo chmod 644 /etc/cron.d/nexoraa-db-backup
  echo "Nightly backup scheduled (02:00 IST). Running one now to check it works..."
  exec bash "$SCRIPT" "$BUCKET" "$TOPIC"
fi

BUCKET="${1:?usage: backup-db.sh <bucket> [alert-topic-arn]}"
TOPIC="${2:-}"
REGION="${AWS_REGION:-ap-south-1}"

alert() {
  echo "!! $1"
  if [ -n "$TOPIC" ]; then
    aws sns publish --region "$REGION" --topic-arn "$TOPIC" \
      --subject "Nexoraa: database backup FAILED" \
      --message "$1 (server $(hostname), $(date -u +%FT%TZ)). See ~/deploy-logs/backup.log." >/dev/null || true
  fi
}
trap 'alert "Backup failed at line $LINENO"' ERR

command -v mongodump >/dev/null || { alert "mongodump not installed"; exit 1; }
command -v aws >/dev/null || { alert "aws CLI not installed"; exit 1; }

STAMP="$(date -u +%Y-%m-%dT%H%MZ)"
mapfile -t URIS < <(grep -h '^MONGODB_URI=' "$ENV_DIR"/*.env | cut -d= -f2- | sort -u)
for uri in "${URIS[@]}"; do
  db="${uri#*://}"; db="${db#*/}"; db="${db%%\?*}"; db="${db:-test}"
  file="$(mktemp /tmp/nexoraa-backup-XXXXXX.archive.gz)"
  mongodump --uri="$uri" --archive="$file" --gzip --quiet
  aws s3 cp "$file" "s3://$BUCKET/daily/$db/$STAMP.archive.gz" --region "$REGION" --only-show-errors
  echo "$(date -u +%FT%TZ) backup ok: s3://$BUCKET/daily/$db/$STAMP.archive.gz ($(du -h "$file" | cut -f1))"
  rm -f "$file"
done
