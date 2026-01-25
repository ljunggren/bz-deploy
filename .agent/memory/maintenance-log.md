# Maintenance Log

## Node.js Upgrade Plan (Traffic Servers)

**Status:** Blocked - requires coordinated upgrade with MongoDB/Mongoose
**Current Version:** v20.11.1
**Target Version:** v24.13.0 (pinned - do not change without explicit request)

### Traffic Servers (Affected)

| Server | Role | Hostname | Node Version |
| :--- | :--- | :--- | :--- |
| staging-bh | Staging | stg1bh.boozang.com | v20.20.0 (rolled back) |
| production-bh | ai server | prd1bh.boozang.com | v20.x |
| production-fr | eu server | prd1fr.boozang.com | v20.x |

### Rollback Reason (2026-01-25)

**Node.js 24 upgrade failed** due to MongoDB driver incompatibility.

**Root Cause:**
- `connect-mongodb-session` package bundles its own older MongoDB driver
- This bundled driver is incompatible with Node.js 24
- Sessions failed to store/retrieve, causing token authentication failures
- Error: `connection to 54.39.178.1:27017 closed`

**Symptoms:**
- Test runner reported: "Failed to load by token"
- Test runner reported: "Boozang server not ready"
- Playwright browser contexts closed unexpectedly

**Resolution:**
Node.js 24 upgrade must be done **in concert** with:
1. Mongoose 5 → 8 migration (async/await refactor)
2. MongoDB driver updates across all packages
3. MongoDB 8.0 server upgrade

See `../bz/.agent/memory/maintenance-log.md` for full migration plan.

### Upgrade Order

1. **staging-bh** - Test the upgrade first
2. **production-fr** - eu server
3. **production-bh** - ai server (primary)

### Ansible Role (Updated)

The `roles/nodejs/tasks/main.yml` now deploys Node.js 24.x:
```yaml
url: https://deb.nodesource.com/setup_24.x
```

### Upgrade Scripts

| Script | Server | Purpose |
| :--- | :--- | :--- |
| `staging-nodejs-upgrade.sh` | staging-bh | Run first |
| `production-fr-nodejs-upgrade.sh` | eu server | Run second |
| `production-bh-nodejs-upgrade.sh` | ai server | Run last |

### Rollback Scripts

| Script | Server |
| :--- | :--- |
| `staging-nodejs-rollback.sh` | staging-bh |
| `production-fr-nodejs-rollback.sh` | eu server |
| `production-bh-nodejs-rollback.sh` | ai server |

### Playbooks

- `nodejs-upgrade.yml` - Full upgrade with backup, verification, and app restart
- `nodejs-rollback.yml` - Rollback to Node.js 20.x

---

### Manual Upgrade Procedure (Per Server)

Use this for testing before updating Ansible role.

#### Pre-flight Checks

```bash
# Check current Node.js version
node --version
# Current: v20.11.1

# Check current npm version
npm --version

# Check how Node was installed
which node
# Expected: /usr/bin/node (apt installed)

# Check disk space (need ~500MB)
df -h /

# Check if application is running
pm2 list

# Check PM2 app details
pm2 show server
```

#### Backup Before Upgrade

```bash
# Backup current node_modules (in case of rollback)
cd /var/www/bz-dist
tar -czf ~/node_modules_backup_$(date +%Y%m%d).tar.gz node_modules

# Note current package-lock.json
cp package-lock.json ~/package-lock_backup_$(date +%Y%m%d).json
```

#### Upgrade Steps

```bash
# 1. Stop the application
pm2 stop server

# 2. Save PM2 process list (for auto-restart after reboot)
pm2 save

# 3. Remove existing Node.js (installed via apt)
sudo apt remove nodejs npm -y
sudo apt autoremove -y

# Clean up any leftover files
sudo rm -rf /usr/lib/node_modules
sudo rm -f /usr/bin/node /usr/bin/npm /usr/bin/npx

# 4. Install NodeSource repository for Node.js 24.x
curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -

# 5. Install Node.js
sudo apt install nodejs -y

# 6. Verify installation
node --version
# Expected: v24.13.0

npm --version
# Expected: v11.6.2

# 7. Install build tools for native modules (if not already installed)
sudo apt install build-essential python3 -y

# 8. Reinstall application dependencies
cd /var/www/bz-dist
rm -rf node_modules
npm install

# 9. Restart the application with PM2
pm2 start server

# 10. Verify application is running
pm2 list
pm2 logs server --lines 20

# 11. Test the application
curl -s http://localhost:3000 | head -5
curl -s http://localhost:80 | head -5
```

#### Rollback Procedure (if upgrade fails)

```bash
# 1. Stop the application
pm2 stop server

# 2. Remove Node.js 24.x
sudo apt remove nodejs -y

# 3. Install previous Node.js version (20.x)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install nodejs -y

# 4. Verify rollback
node --version
# Should show: v20.x.x

# 5. Restore node_modules
cd /var/www/bz-dist
rm -rf node_modules
tar -xzf ~/node_modules_backup_*.tar.gz

# 6. Restart application
pm2 start server

# 7. Verify
pm2 list
curl -s http://localhost:3000 | head -5
```

#### Post-upgrade Verification

```bash
# Check PM2 status
pm2 list

# Check application logs for errors
pm2 logs server --lines 100

# Or check log files directly
tail -100 /home/ubuntu/.pm2/logs/server-error.log
tail -100 /home/ubuntu/.pm2/logs/server-out.log

# Test the application (direct to Node)
curl -s http://localhost:3000 | head -5

# Test via Nginx
curl -s http://localhost:80 | grep -i boozang

# Check for deprecation warnings
pm2 logs server --lines 500 | grep -i "deprecat"

# Check memory usage hasn't spiked
pm2 monit
```

**Post-upgrade checklist:**
- [ ] Node.js version is 24.13.0: `node --version`
- [ ] npm version is 11.6.2: `npm --version`
- [ ] PM2 shows app "online": `pm2 list`
- [ ] No rapid restarts (↺ column stable): `pm2 list`
- [ ] No errors in logs: `pm2 logs server --lines 50`
- [ ] App responds on port 3000: `curl -s http://localhost:3000 | head -3`
- [ ] Nginx proxy works: `curl -s http://localhost:80 | head -3`
- [ ] External access works: `curl -s https://ai.boozang.com | head -3`
- [ ] Login functionality works (manual test)
- [ ] No critical deprecation warnings in logs

---

### Ansible-Based Upgrade (After Manual Testing)

Once manual upgrade is validated on staging:

1. Update `roles/nodejs/tasks/main.yml`:
   - Change `setup_20.x` to `setup_24.x`

2. Run staging deployment:
   ```bash
   ./staging-deploy.sh
   ```

3. Verify staging works, then deploy to production:
   ```bash
   ./production-fr-deploy.sh  # eu server first
   ./production-bh-deploy.sh  # ai server after eu verified
   ```

---

## Related: Application Code Migration

**Note:** The Node.js 24 upgrade on traffic servers should be coordinated with the Mongoose callback-to-async migration in the main `bz` codebase. See `../bz/.agent/memory/maintenance-log.md` for details on:
- Mongoose 5 → 8 migration
- MongoDB 5.0 → 8.0 upgrade
- OS normalization (CentOS → Ubuntu)
