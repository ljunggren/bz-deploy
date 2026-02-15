#!/bin/bash
cd "$(dirname "$0")/.."
# Fetch latest hourly backup from db1bh.boozang.com (AI + staging)
set -e

HOST="ubuntu@db1bh.boozang.com"
BACKUP_DIR="/mnt/disk/mongodb-backups"
LOCAL_DIR="./backups/db1bh.boozang.com"

# Find latest hourly backup on remote
LATEST=$(ssh -o ConnectTimeout=5 "$HOST" "ls -1t ${BACKUP_DIR}/mongodb_hourly_*.tar.gz | head -1" 2>/dev/null)

if [ -z "$LATEST" ]; then
  echo "ERROR: No hourly backups found on db1bh.boozang.com"
  exit 1
fi

FILENAME=$(basename "$LATEST")
mkdir -p "$LOCAL_DIR"

echo "Fetching latest hourly backup from db1bh.boozang.com"
echo "Remote: $LATEST"
echo "Local:  $LOCAL_DIR/$FILENAME"
echo ""

rsync -avz --progress "$HOST:$LATEST" "$LOCAL_DIR/$FILENAME"

echo ""
echo "Done! Backup saved to $LOCAL_DIR/$FILENAME"
