#!/bin/bash
#
# Full system healthcheck for Boozang infrastructure
# Checks: traffic servers, MongoDB, backups, disk space
#

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'
BOLD='\033[1m'

PASS=0
WARN=0
FAIL=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS+1)); }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; WARN=$((WARN+1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL=$((FAIL+1)); }

# --- Traffic Servers ---

TRAFFIC_SERVERS=(
  "staging-bh|stg1bh.boozang.com"
  "ai-prod|prd1bh.boozang.com"
  "eu-prod|prd1fr.boozang.com"
)

HTTPS_URLS=(
  "ai.boozang.com"
  "eu.boozang.com"
)

echo -e "\n${BOLD}=== HTTPS Endpoints ===${NC}"
for url in "${HTTPS_URLS[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$url" 2>/dev/null || echo "000")
  time=$(curl -s -o /dev/null -w "%{time_total}" --max-time 10 "https://$url" 2>/dev/null || echo "timeout")
  if [ "$code" = "200" ]; then
    pass "$url — HTTP $code (${time}s)"
  else
    fail "$url — HTTP $code"
  fi
done

echo -e "\n${BOLD}=== Traffic Servers (PM2) ===${NC}"
for entry in "${TRAFFIC_SERVERS[@]}"; do
  IFS='|' read -r name host <<< "$entry"
  pm2_out=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "ubuntu@$host" "pm2 jlist 2>/dev/null" 2>/dev/null) || { fail "$name ($host) — SSH failed"; continue; }

  status=$(echo "$pm2_out" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['pm2_env']['status'])" 2>/dev/null || echo "unknown")
  version=$(echo "$pm2_out" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['pm2_env']['version'])" 2>/dev/null || echo "?")
  restarts=$(echo "$pm2_out" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['pm2_env']['restart_time'])" 2>/dev/null || echo "?")
  mem_mb=$(echo "$pm2_out" | python3 -c "import sys,json; d=json.load(sys.stdin); print(round(d[0]['monit']['memory']/1024/1024))" 2>/dev/null || echo "?")
  node_ver=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "ubuntu@$host" "node --version" 2>/dev/null || echo "?")

  if [ "$status" = "online" ]; then
    pass "$name — v${version}, ${node_ver}, ${mem_mb}MB, ${restarts} restarts"
  else
    fail "$name — status: $status"
  fi
done

# --- MongoDB Servers ---

DB_SERVERS=(
  "db1bh|db1bh.boozang.com"
  "db1fr|db1fr.boozang.com"
)

MONGO_URI="mongodb://admin:DevoIsAMongoDatabase@localhost:27017/admin"

echo -e "\n${BOLD}=== MongoDB Servers ===${NC}"
for entry in "${DB_SERVERS[@]}"; do
  IFS='|' read -r name host <<< "$entry"

  ok=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "ubuntu@$host" \
    "mongosh --quiet --eval 'db.adminCommand({serverStatus:1}).ok' '$MONGO_URI'" 2>/dev/null) || { fail "$name ($host) — SSH/mongosh failed"; continue; }

  if [ "$ok" = "1" ]; then
    stats=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "ubuntu@$host" \
      "mongosh --quiet --eval 'var s=db.getSiblingDB(\"boozang-production\").stats(); s.collections+\" cols, \"+s.objects+\" docs\"' '$MONGO_URI'" 2>/dev/null || echo "stats unavailable")
    pass "$name ($host) — $stats"
  else
    fail "$name ($host) — serverStatus returned $ok"
  fi
done

# --- Backups ---

echo -e "\n${BOLD}=== Backups ===${NC}"
for entry in "${DB_SERVERS[@]}"; do
  IFS='|' read -r name host <<< "$entry"

  # Check latest daily backup
  latest_daily=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "ubuntu@$host" \
    "ls -1t /mnt/disk/mongodb-backups/mongodb_daily_*.tar.gz 2>/dev/null | head -1" 2>/dev/null || echo "")
  if [ -n "$latest_daily" ]; then
    daily_date=$(basename "$latest_daily" | sed 's/mongodb_daily_\([0-9]*\)_.*/\1/')
    today=$(date +%Y%m%d)
    if [ "$daily_date" = "$today" ]; then
      pass "$name daily — $daily_date (today)"
    else
      warn "$name daily — latest is $daily_date (not today)"
    fi
  else
    fail "$name daily — no backups found"
  fi

  # Check latest hourly backup
  latest_hourly=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "ubuntu@$host" \
    "ls -1t /mnt/disk/mongodb-backups/mongodb_hourly_*.tar.gz 2>/dev/null | head -1" 2>/dev/null || echo "")
  if [ -n "$latest_hourly" ]; then
    hourly_ts=$(basename "$latest_hourly" | sed 's/mongodb_hourly_\([0-9_]*\)\.tar.gz/\1/')
    pass "$name hourly — latest: $hourly_ts"
  else
    fail "$name hourly — no backups found"
  fi
done

# --- Disk Space ---

echo -e "\n${BOLD}=== Disk Space ===${NC}"
for entry in "${DB_SERVERS[@]}"; do
  IFS='|' read -r name host <<< "$entry"
  disk_info=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "ubuntu@$host" \
    "df -h /mnt/disk | tail -1 | awk '{print \$3\"/\"\$2\" (\"\$5\" used)\"}'" 2>/dev/null || echo "unavailable")
  usage_pct=$(echo "$disk_info" | sed -n 's/.*(\([0-9]*\)% used).*/\1/p')
  usage_pct=${usage_pct:-0}
  if [ "$usage_pct" -lt 80 ]; then
    pass "$name backup disk — $disk_info"
  elif [ "$usage_pct" -lt 90 ]; then
    warn "$name backup disk — $disk_info"
  else
    fail "$name backup disk — $disk_info"
  fi
done

for entry in "${TRAFFIC_SERVERS[@]}"; do
  IFS='|' read -r name host <<< "$entry"
  disk_info=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "ubuntu@$host" \
    "df -h / | tail -1 | awk '{print \$3\"/\"\$2\" (\"\$5\" used)\"}'" 2>/dev/null || echo "unavailable")
  usage_pct=$(echo "$disk_info" | sed -n 's/.*(\([0-9]*\)% used).*/\1/p')
  usage_pct=${usage_pct:-0}
  if [ "$usage_pct" -lt 80 ]; then
    pass "$name root — $disk_info"
  elif [ "$usage_pct" -lt 90 ]; then
    warn "$name root — $disk_info"
  else
    fail "$name root — $disk_info"
  fi
done

# --- Summary ---

echo -e "\n${BOLD}=== Summary ===${NC}"
echo -e "  ${GREEN}Passed: $PASS${NC}  ${YELLOW}Warnings: $WARN${NC}  ${RED}Failed: $FAIL${NC}"

if [ "$FAIL" -gt 0 ]; then
  exit 1
elif [ "$WARN" -gt 0 ]; then
  exit 0
else
  exit 0
fi
