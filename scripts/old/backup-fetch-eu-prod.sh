#!/bin/bash
cd "$(dirname "$0")/.."
# Fetch production backup from old EU database server (db1de.boozang.com)
set -e

DATE=${1:-$(date +%m%d%y)}
LOCAL_DIR="./backups/db1de.boozang.com/production/${DATE}"
REMOTE_PATH="/mnt/disk/backup/mongo/${DATE}/boozang-production/"

echo "Fetching backup from db1de.boozang.com for date: ${DATE}"
echo "Remote: ${REMOTE_PATH}"
echo "Local:  ${LOCAL_DIR}"

mkdir -p "${LOCAL_DIR}"
rsync -avz --progress centos@db1de.boozang.com:"${REMOTE_PATH}" "${LOCAL_DIR}/"

echo "Done! Backup saved to ${LOCAL_DIR}"
