#!/usr/bin/env bash
# Move the production MongoDB to a new cluster (e.g. Atlas in Mumbai) and point every
# service at it. The OLD database is only read, never changed, so it stays as a backup.
#
#   bash infra/aws-ec2/migrate-db.sh 'mongodb+srv://user:pass@new-cluster.xxxxx.mongodb.net/'
#
# Steps: install mongodump/mongorestore → stop services (no writes during the copy) →
# dump every database the services use → restore into the new cluster → compare
# per-collection document counts → rewrite MONGODB_URI in ~/nexoraa-env/*.env (backups
# kept as *.env.before-migrate) → restart services. If the copy or the count check fails,
# services are restarted on the OLD database and nothing is switched.
set -euo pipefail

NEW_BASE="${1:?usage: migrate-db.sh <new cluster connection string>}"
ENV_DIR="${NEXORAA_ENV_DIR:-$HOME/nexoraa-env}"
WORK="$HOME/db-migration-$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$WORK"

echo "==> MongoDB tools"
if ! command -v mongodump >/dev/null; then
  curl -fsSL -o "$WORK/tools.deb" \
    https://fastdl.mongodb.org/tools/db/mongodb-database-tools-ubuntu2404-x86_64-100.12.0.deb
  sudo apt-get install -y "$WORK/tools.deb" >/dev/null
fi
mongodump --version | head -1

# Every distinct URI the services use today (normally one shared database).
mapfile -t OLD_URIS < <(grep -h '^MONGODB_URI=' "$ENV_DIR"/*.env | cut -d= -f2- | sort -u)
echo "==> ${#OLD_URIS[@]} distinct source database URI(s)"

# Database name = path segment after the host (before any '?').
db_of() { local rest="${1#*://}"; rest="${rest#*/}"; rest="${rest%%\?*}"; echo "${rest:-test}"; }
query_of() { [[ "$1" == *\?* ]] && echo "?${1#*\?}" || echo ''; }
# "mongodb+srv://user:pass@host/anything?opts" → NEW_HOST="mongodb+srv://user:pass@host"
NEW_SCHEME="${NEW_BASE%%://*}"
NEW_AUTHORITY="${NEW_BASE#*://}"; NEW_AUTHORITY="${NEW_AUTHORITY%%[/?]*}"
NEW_HOST="$NEW_SCHEME://$NEW_AUTHORITY"
NEW_QUERY="$(query_of "$NEW_BASE")"; [ -n "$NEW_QUERY" ] || NEW_QUERY='?retryWrites=true&w=majority'
[[ "$NEW_AUTHORITY" == *@* ]] || { echo "The new connection string must include user:password@"; exit 1; }

echo "==> Checking the new cluster accepts this login (before any downtime)"
if ! login_check="$(mongoexport --uri="$NEW_HOST/$(db_of "${OLD_URIS[0]}")$NEW_QUERY" \
      --collection=__migration_login_check --quiet 2>&1)"; then
  echo "!! Cannot log in to the new cluster:"
  echo "$login_check" | sed -E 's#//[^@]*@#//***@#' | tail -3
  echo
  echo "Fix in Atlas (the NEW project): Database Access → user/password, and"
  echo "Network Access → allow this server's IP. A password containing @ must be written as %40."
  echo "Nothing was stopped or changed."
  exit 1
fi
echo "   login ok"

echo "==> Stopping services (no writes during the copy)"
pm2 stop all >/dev/null

restart_old() { echo "!! Migration failed — restarting services on the OLD database"; pm2 start all >/dev/null; exit 1; }
trap restart_old ERR

for uri in "${OLD_URIS[@]}"; do
  db="$(db_of "$uri")"
  echo "==> Dump  $db"
  mongodump --uri="$uri" --out="$WORK/dump" --quiet
  echo "==> Restore $db → new cluster"
  mongorestore --uri="$NEW_HOST/$NEW_QUERY" --nsInclude="$db.*" --drop "$WORK/dump" 2>&1 \
    | sed -E 's#//[^@]*@#//***@#' | grep -E 'error|Failed|document\(s\) restored' || true
  [ "${PIPESTATUS[0]}" -eq 0 ]
done

echo "==> Verifying document counts"
for uri in "${OLD_URIS[@]}"; do
  db="$(db_of "$uri")"
  # mongodump wrote one .bson per collection; compare its count with the new cluster.
  mismatches=0
  for bson in "$WORK/dump/$db"/*.bson; do
    coll="$(basename "$bson" .bson)"
    src=$(bsondump --quiet "$bson" | wc -l)
    dst=$(mongoexport --uri="$NEW_HOST/$db$NEW_QUERY" --collection="$coll" --quiet --type=json 2>/dev/null | wc -l)
    status="ok"; [ "$src" -eq "$dst" ] || { status="MISMATCH"; mismatches=$((mismatches+1)); }
    printf '   %-40s %8s → %-8s %s\n' "$db.$coll" "$src" "$dst" "$status"
  done
  [ "$mismatches" -eq 0 ] || { echo "!! $mismatches collection(s) differ"; false; }
done

echo "==> Switching services to the new cluster"
for f in "$ENV_DIR"/*.env; do
  grep -q '^MONGODB_URI=' "$f" || continue
  cp "$f" "$f.before-migrate"
  db="$(db_of "$(grep '^MONGODB_URI=' "$f" | cut -d= -f2-)")"
  sed -i "s#^MONGODB_URI=.*#MONGODB_URI=$NEW_HOST/$db$NEW_QUERY#" "$f"
  chmod 600 "$f"
done
trap - ERR

pm2 start all >/dev/null
sleep 15
pm2 status
echo
echo "Done. Old database untouched (rollback: copy ~/nexoraa-env/*.env.before-migrate back over *.env, then pm2 restart all)."
echo "Dump kept in $WORK (delete once you're happy)."
