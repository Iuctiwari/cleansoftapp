#!/bin/bash
# =============================================================================
# docker/mongodb/init-replica.sh
# One-shot container that initialises the MongoDB replica set on first boot.
# Runs AFTER the mongodb service is healthy.
#
# In development (no auth): connects without credentials.
# In production (auth enabled): connects with MONGO_INITDB_ROOT_USERNAME/PASSWORD.
# =============================================================================
set -euo pipefail

MONGO_HOST="${MONGO_HOST:-mongodb}"
MONGO_PORT="${MONGO_PORT:-27017}"
REPLICA_SET="${REPLICA_SET:-rs0}"

# Build connection string
if [ -n "${MONGO_INITDB_ROOT_USERNAME:-}" ] && [ -n "${MONGO_INITDB_ROOT_PASSWORD:-}" ]; then
  CONN_STRING="mongodb://${MONGO_INITDB_ROOT_USERNAME}:${MONGO_INITDB_ROOT_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/?authSource=admin"
else
  CONN_STRING="mongodb://${MONGO_HOST}:${MONGO_PORT}"
fi

echo "[mongo-init] Waiting for MongoDB to be ready at ${MONGO_HOST}:${MONGO_PORT}..."

# Wait until mongosh can reach the server
until mongosh "${CONN_STRING}" --eval "db.adminCommand('ping')" --quiet > /dev/null 2>&1; do
  echo "[mongo-init] MongoDB not yet reachable — retrying in 2s..."
  sleep 2
done

echo "[mongo-init] MongoDB is reachable. Checking replica set status..."

# Check if replica set is already initialised
RS_STATUS=$(mongosh "${CONN_STRING}" --eval "
  try {
    const s = rs.status();
    s.ok === 1 ? 'INITIALIZED' : 'NOT_INITIALIZED';
  } catch (e) {
    'NOT_INITIALIZED';
  }
" --quiet 2>&1 | tail -1)

if [ "${RS_STATUS}" = "INITIALIZED" ]; then
  echo "[mongo-init] Replica set '${REPLICA_SET}' is already initialised — nothing to do."
  exit 0
fi

echo "[mongo-init] Initialising replica set '${REPLICA_SET}'..."

mongosh "${CONN_STRING}" --eval "
  rs.initiate({
    _id: '${REPLICA_SET}',
    members: [
      { _id: 0, host: '${MONGO_HOST}:${MONGO_PORT}', priority: 1 }
    ]
  });
" --quiet

echo "[mongo-init] Waiting for PRIMARY election..."
until mongosh "${CONN_STRING}" --eval "
  const status = rs.status();
  const primary = status.members.find(m => m.stateStr === 'PRIMARY');
  primary ? quit(0) : quit(1);
" --quiet > /dev/null 2>&1; do
  echo "[mongo-init] Waiting for PRIMARY..."
  sleep 2
done

echo "[mongo-init] Replica set '${REPLICA_SET}' initialised successfully with PRIMARY elected."
