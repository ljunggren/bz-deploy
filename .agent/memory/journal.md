# Project Journal

## 2026-02-06

### Session: MongoDB 8.0 Cutover Preparation

**Work Completed:**
- Fetched fresh production backups from old CentOS servers:
  - `db1be2.boozang.com` → `./backups/db1be2.boozang.com/production/fresh_020626/` (677K docs, ~483 MB)
  - `db1de.boozang.com` → `./backups/db1de.boozang.com/production/fresh_020626/` (1.68M docs, ~750 MB)
- Restored fresh backups to new MongoDB 8.0 servers:
  - `db1bh.boozang.com` — 675,697 documents, 0 failures
  - `db1fr.boozang.com` — 1,685,794 documents, 0 failures
- Updated MongoDB connection strings in `bz` app codebase (7 files):
  - `db-be.boozang.com` → `db1bh.boozang.com` (production-bh, production-be, staging-be, staging-next, build-be)
  - `db-de.boozang.com` → `db1fr.boozang.com` (production-fr, production-de)
- Committed and pushed to `bz` repo: `cfa4111e9`
- Deployed to staging-bh: v11.0.15, healthy, HTTP 200

**Key Findings:**
- Mongoose 5→8 migration is complete in `bz` repo (merged Feb 4, Mongoose 8.22.1)
- Node.js 24 upgrade blocker is resolved — ready to attempt after DB cutover
- Staging-bh already pointed to db1bh.boozang.com (since Jan 26) and works fine without auth credentials

**Current State:**
| Server | Status | DB Connection |
| :--- | :--- | :--- |
| staging-bh | Deployed, testing | db1bh.boozang.com (new) |
| production-bh | Pending deploy | Code updated, not yet deployed |
| production-fr | Pending deploy | Code updated, not yet deployed |

**Next Steps:**
- Manual testing baseline on staging (in progress)
- Deploy to production-fr (EU) after staging verified
- Deploy to production-bh (AI) after EU verified
- Then attempt Node.js 24 upgrade (staging → EU → AI)

---

## 2026-01-26

### Session: MongoDB 8.0 Infrastructure Setup

**Work Completed:**
- Installed MongoDB 8.0.17 on new database servers:
  - `db1bh.boozang.com` (Bahrain/AI region)
  - `db1fr.boozang.com` (Frankfurt/EU region)
- Configured MongoDB with authentication enabled
- Set up 100GB backup disks on both servers (`/dev/sdb` → `/mnt/disk`)
- Created automated backup system:
  - Hourly backups (2 day retention)
  - Daily backups at 2am (30 day retention)
  - Backup location: `/mnt/disk/mongodb-backups/`

**Database Migration:**
- Created `mongodb-restore-bh.sh` and `mongodb-restore-fr.sh` scripts
- Restored databases from old CentOS servers:
  - `db1de.boozang.com` → `db1fr.boozang.com` (boozang-production: 1.68M docs)
  - `db1be2.boozang.com` → `db1bh.boozang.com` (boozang-production: 677K docs)
  - `db1be2.boozang.com` → `db1bh.boozang.com` (boozang-next: staging)

**Backup Fetch Scripts:**
- Created rsync-based scripts for fetching backups from old servers:
  - `backup-fetch-eu-prod.sh` (db1de → local)
  - `backup-fetch-ai-prod.sh` (db1be2 → local)
  - `backup-fetch-staging.sh` (db1be2 → local)

**MongoDB Role Updates:**
- Made backup tasks conditional (`mongodb_backup_enabled`)
- Made role idempotent for re-runs
- Added dynamic Ubuntu version detection for repo URL

**Files Created:**
- `database.yml` - MongoDB deployment playbook
- `roles/mongodb/` - MongoDB installation role
- `inventories/db-bh`, `inventories/db-fr` - New DB server inventories
- `inventories/db-old-bh`, `inventories/db-old-de` - Old server inventories
- `backup-fetch-*.sh` - Backup retrieval scripts
- `mongodb-restore-*.sh` - Database restore scripts

**Current State:**
| Server | MongoDB | Databases |
|--------|---------|-----------|
| db1bh.boozang.com | 8.0.17 | boozang-production, boozang-next |
| db1fr.boozang.com | 8.0.17 | boozang-production |

**Credentials:**
- Admin user: `admin`
- Password: `DevoIsAMongoDatabase`

---

## 2026-01-25

### Session: Node.js Upgrade Plan Migration

**Work Completed:**
- Replicated Node.js upgrade plan from `bz` project
- Created `maintenance-log.md` with:
  - Traffic servers upgrade plan (Node.js 20 → 24)
  - Manual upgrade procedure with pre-flight checks
  - Rollback procedure
  - Post-upgrade verification checklist
  - Ansible role update instructions
- Updated `infrastructure.md` with:
  - Detailed server landscape table
  - Corrected locations: Beauharnois (bh), Frankfurt (fr)
  - Traffic server configuration details
  - PM2 and Nginx settings
  - Ansible roles overview
  - External dependencies (MongoDB)

**Key Notes:**
- Current `roles/nodejs/tasks/main.yml` deploys Node.js 20.x
- Upgrade should follow: staging → eu server → ai server
- Node.js upgrade on traffic servers should coordinate with Mongoose migration in bz project

**Next Steps:**
- Run `./staging-nodejs-upgrade.sh` to upgrade staging
- Verify staging works
- Run `./production-fr-nodejs-upgrade.sh` for eu server
- Run `./production-bh-nodejs-upgrade.sh` for ai server

### Session: Node.js 24 Upgrade Failed - Rolled Back

**Timeline:**
1. Upgraded staging to Node.js v24.13.0
2. Deployed app v10.2.0
3. Updated PM2 daemon (5.3.1 → 6.0.14)
4. Ran regression tests - **FAILED**
5. Investigated: MongoDB session driver incompatibility
6. Rolled back to Node.js v20.20.0
7. Redeployed app v10.1.2

**Root Cause:**
`connect-mongodb-session` bundles an older MongoDB driver incompatible with Node.js 24. Sessions couldn't be stored/retrieved, causing token auth failures.

**Error Evidence:**
```
Error setting session: connection to 54.39.178.1:27017 closed
Failed to load by token
Boozang server not ready
```

**Decision:**
Node.js 24 upgrade **blocked** until coordinated with:
- Mongoose 5 → 8 migration
- MongoDB driver updates
- MongoDB 8.0 server upgrade

**Current State:**
| Server | Node.js | App |
| :--- | :--- | :--- |
| staging-bh | v20.20.0 | v10.1.2 |
| production-fr | v20.x | - |
| production-bh | v20.x | - |

**Assets Created (ready for future use):**
- `nodejs-upgrade.yml` - upgrade playbook
- `nodejs-rollback.yml` - rollback playbook
- Upgrade/rollback scripts for all environments

---

### Session: Node.js Upgrade Scripts Created

**Work Completed:**
- Updated `roles/nodejs/tasks/main.yml` to use Node.js 24.x
- Created `nodejs-upgrade.yml` playbook with:
  - Pre-flight checks (version, disk space)
  - Backup (package-lock.json)
  - Full upgrade process
  - Dependency reinstall
  - PM2 restart
  - Verification tests
- Created `nodejs-rollback.yml` playbook for emergencies
- Created upgrade scripts:
  - `staging-nodejs-upgrade.sh`
  - `production-fr-nodejs-upgrade.sh`
  - `production-bh-nodejs-upgrade.sh`
- Created rollback scripts:
  - `staging-nodejs-rollback.sh`
  - `production-fr-nodejs-rollback.sh`
  - `production-bh-nodejs-rollback.sh`
- All playbooks pass syntax check

---

### Session: Initial Agent Directory Setup

**Work Completed:**
- Created `.agent/` directory structure with subdirectories:
  - `context/` - Project and infrastructure knowledge
  - `instructions/` - Operational guidelines
  - `memory/` - Session logs
- Created core documentation files:
  - `README.md` - Agent directory overview
  - `instructions.md` - Main instruction index
- Created context files:
  - `project-context.md` - Ansible deployment overview
  - `infrastructure.md` - Server environments and inventory
- Created instruction files:
  - `general.md` - Tone and verification rules
  - `ansible.md` - Ansible best practices
  - `deployment.md` - Deployment workflows
  - `documentation.md` - Documentation standards
  - `commands.md` - Session commands
- Created root documentation:
  - `AGENTS.md` - AI agent quick reference
  - `CLAUDE.md` - Human-readable project guide

**Key Decisions:**
- Adapted structure from bz project but focused on Ansible/deployment workflows
- Emphasized deployment procedures and environment management
- Included comprehensive deployment scripts documentation

**Open Items:**
- None - clean initial state for future sessions
