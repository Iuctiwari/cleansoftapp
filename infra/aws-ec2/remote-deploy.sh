#!/usr/bin/env bash
# Entry point for GitHub Actions (via AWS Systems Manager). Runs deploy.sh with
# the full log saved on the server, and prints only the tail — SSM returns just
# the first 24 KB of output, and on failure the useful part is the end.
#   Full logs: ~/deploy-logs/
set -uo pipefail

LOG_DIR="$HOME/deploy-logs"
mkdir -p "$LOG_DIR"
LOG="$LOG_DIR/deploy-$(date -u +%Y%m%d-%H%M%S).log"

bash "$(dirname "$0")/deploy.sh" "$@" >"$LOG" 2>&1
status=$?

tail -n 200 "$LOG"
echo
echo "Full log on the server: $LOG (exit code $status)"
# Keep the 20 most recent logs.
ls -1t "$LOG_DIR"/deploy-*.log | tail -n +21 | xargs -r rm -f
exit "$status"
