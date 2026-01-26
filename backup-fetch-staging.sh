#!/bin/bash
# Fetch next/staging backup from old AI database server (db1be2.boozang.com)
set -e

DATE=${1:-$(date +%m%d%y)}
LOCAL_DIR="./backups/db1be2.boozang.com/next/${DATE}"
REMOTE_PATH="/mnt/disk/backup/mongo/${DATE}/boozang-next/"

echo "Fetching backup from db1be2.boozang.com for date: ${DATE}"
echo "Remote: ${REMOTE_PATH}"
echo "Local:  ${LOCAL_DIR}"

mkdir -p "${LOCAL_DIR}"
rsync -avz --progress centos@db1be2.boozang.com:"${REMOTE_PATH}" "${LOCAL_DIR}/"

echo "Done! Backup saved to ${LOCAL_DIR}"
