#!/bin/bash
cd "$(dirname "$0")/.."
# Restore MongoDB from db1de.boozang.com (old EU) to db1fr.boozang.com (new EU)
set -e

DATE=${1:-$(date +%m%d%y)}
DB_NAME="boozang-production"
OLD_SERVER="centos@db1de.boozang.com"
NEW_SERVER="ubuntu@db1fr.boozang.com"
REMOTE_BACKUP_PATH="/mnt/disk/backup/mongo/${DATE}/${DB_NAME}"
LOCAL_BACKUP_DIR="./backups/restore-fr/${DATE}"
MONGO_URI="mongodb://admin:DevoIsAMongoDatabase@localhost:27017/?authSource=admin"

echo "=== MongoDB Restore: db1de -> db1fr ==="
echo "Date: ${DATE}"
echo "Database: ${DB_NAME}"
echo ""

# Step 1: Fetch backup from old server
echo "[1/4] Fetching backup from ${OLD_SERVER}..."
mkdir -p "${LOCAL_BACKUP_DIR}"
rsync -avz --progress ${OLD_SERVER}:"${REMOTE_BACKUP_PATH}/" "${LOCAL_BACKUP_DIR}/${DB_NAME}/"

# Step 2: Push backup to new server
echo ""
echo "[2/4] Pushing backup to ${NEW_SERVER}..."
ssh ${NEW_SERVER} "mkdir -p /tmp/mongodb-restore"
rsync -avz --progress "${LOCAL_BACKUP_DIR}/${DB_NAME}/" ${NEW_SERVER}:/tmp/mongodb-restore/${DB_NAME}/

# Step 3: Run mongorestore on new server
echo ""
echo "[3/4] Running mongorestore on ${NEW_SERVER}..."
ssh ${NEW_SERVER} "mongorestore --uri='${MONGO_URI}' --drop --db=${DB_NAME} /tmp/mongodb-restore/${DB_NAME}/"

# Step 4: Cleanup
echo ""
echo "[4/4] Cleaning up temporary files..."
ssh ${NEW_SERVER} "rm -rf /tmp/mongodb-restore"

echo ""
echo "=== Restore complete! ==="
echo "Restored ${DB_NAME} from db1de.boozang.com to db1fr.boozang.com"
