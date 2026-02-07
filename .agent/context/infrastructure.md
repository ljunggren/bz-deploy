# Infrastructure Details

## Server Landscape

| Server Role | OS | Hostname | Inventory | Note |
| :--- | :--- | :--- | :--- | :--- |
| **Management** | Ubuntu 22.04 | mgmt1bh.boozang.com | management-bh | WordPress, MySQL |
| **Staging** | Ubuntu 22.04 | stg1bh.boozang.com | staging-bh | Pre-production |
| **Staging Next** | Ubuntu 22.04 | stgnext1bh.boozang.com | staging-bh-next | Next-gen testing |
| **Production AI** | Ubuntu 22.04 | prd1bh.boozang.com | production-bh | ai.boozang.com |
| **Production EU** | Ubuntu 22.04 | prd1fr.boozang.com | production-fr | eu.boozang.com |

**Locations:**
- **bh** = Beauharnois (OVH Canada)
- **fr** = Frankfurt (OVH Germany)

---

## Traffic Servers (Node.js Application)

Traffic servers run the main Boozang application (Node.js + Express).

### Current Production Setup

| Component | Current | Target |
| :--- | :--- | :--- |
| **OS** | Ubuntu 22.04 LTS | Ubuntu 22.04 LTS |
| **Node.js** | v20.11.1 | v24.13.0 (pinned) |
| **npm** | 10.2.4 | 11.6.2 |
| **Application Path** | /var/www/bz-dist | - |
| **Main Script** | /var/www/bz-dist/server.js | - |
| **App Port** | 3000 | - |
| **Public Ports** | 80, 443 | - |

### Process Management (PM2)

- **PM2 App Name:** `server` (id: 0)
- **PM2 User:** ubuntu
- **NODE_ENV:** `production-bh` (varies per server)
- **Logs:** `/home/ubuntu/.pm2/logs/server-out.log`, `server-error.log`

### Nginx Configuration

- **Config file:** `/etc/nginx/sites-enabled/nodejs_app`
- **Proxy pass:** `http://localhost:3000`
- **SSL:** Managed by Certbot (Let's Encrypt)

---

## Management Server (WordPress)

### Stack
- **Web Server:** Nginx
- **PHP:** PHP-FPM
- **Database:** MySQL
- **CMS:** WordPress

### Applications
- **Boozang Lab** (thelab.boozang.com)
- **Portfolio site** (portfolio.boozang.com)
- **Documentation** (docs.boozang.com)

---

## Inventory Structure

Inventories are located in `inventories/` directory:

```
inventories/
├── staging-bh
├── staging-bh-next
├── production-bh
├── production-fr
└── management-bh
```

## Group Variables

Located in `group_vars/`, defining environment-specific settings:
- Database credentials
- Domain names
- SSL certificate settings
- Application-specific configuration

---

## Deployment Scripts

| Script | Purpose | Inventory |
| :--- | :--- | :--- |
| `staging-deploy.sh` | Deploy to staging | staging-bh |
| `staging-deploy-next.sh` | Deploy to staging-next | staging-bh-next |
| `production-bh-deploy.sh` | Deploy to ai server | production-bh |
| `production-fr-deploy.sh` | Deploy to eu server | production-fr |
| `production-bh-setup.sh` | Initial ai server setup | production-bh |
| `production-fr-setup.sh` | Initial eu server setup | production-fr |
| `management-setup.sh` | Management server setup | management-bh |
| `staging-nodejs-upgrade.sh` | Node.js upgrade (staging) | staging-bh |
| `production-fr-nodejs-upgrade.sh` | Node.js upgrade (eu) | production-fr |
| `production-bh-nodejs-upgrade.sh` | Node.js upgrade (ai) | production-bh |
| `staging-nodejs-rollback.sh` | Node.js rollback (staging) | staging-bh |
| `production-fr-nodejs-rollback.sh` | Node.js rollback (eu) | production-fr |
| `production-bh-nodejs-rollback.sh` | Node.js rollback (ai) | production-bh |

---

## Network & Security

- **SSL/TLS:** Let's Encrypt certificates managed via `https` role
- **Firewall:** UFW managed by `setup` role
- **SSH Access:** Key-based authentication via `github` role
- **Web Server:** Nginx reverse proxy for Node.js applications

---

## Ansible Roles

| Role | Purpose |
| :--- | :--- |
| `setup` | Base system configuration, firewall |
| `nginx` | Web server installation and config |
| `https` | Let's Encrypt SSL certificates |
| `nodejs` | Node.js runtime (currently 20.x, target 24.13.0) |
| `github` | GitHub SSH keys and deployment access |
| `application` | Application deployment and PM2 setup |

---

## Upgrade Status

See `.agent/memory/maintenance-log.md` for active upgrade plans:
- **Node.js 20.11.1 → 24.13.0** on traffic servers (pending)

---

## External Dependencies

### MongoDB

Database servers managed by `database.yml` playbook:
- **db1bh.boozang.com** - MongoDB 8.0.17 on Ubuntu 22.04 (serves ai server + staging)
- **db1fr.boozang.com** - MongoDB 8.0.17 on Ubuntu 22.04 (serves eu server)

Old servers (CentOS 7, MongoDB 5.0.4) still running but no longer used by app:
- `db1be2.boozang.com` (old BH)
- `db1de.boozang.com` (old EU)

### DNS

Managed externally via domain registrar/Cloudflare.
