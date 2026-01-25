# Project Journal

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
