# Deployment Workflows

## Deployment Scripts

All deployment scripts are located in the project root and follow the naming pattern: `{environment}-{action}.sh`

### Available Scripts

| Script | Purpose | Environment |
|--------|---------|-------------|
| `staging-setup.sh` | Initial staging setup | Staging (Bahrain) |
| `staging-deploy.sh` | Deploy to staging | Staging (Bahrain) |
| `staging-deploy-next.sh` | Deploy to next-gen staging | Staging (Next) |
| `staging-deploy-lws.sh` | Deploy to LWS staging | Staging (LWS) |
| `production-bh-setup.sh` | Initial production setup | Production (Bahrain) |
| `production-bh-deploy.sh` | Deploy to production | Production (Bahrain) |
| `production-fr-setup.sh` | Initial production setup | Production (France) |
| `production-fr-deploy.sh` | Deploy to production | Production (France) |
| `management-setup.sh` | Setup management server | Management |
| `app-setup.sh` | Setup applications | Management |

## Standard Deployment Workflow

### 1. Initial Setup (First Time Only)
```bash
# Run setup script for the target environment
./staging-setup.sh
# or
./production-bh-setup.sh
```

This will:
- Configure base system (firewall, users, packages)
- Install Nginx
- Setup Let's Encrypt SSL
- Install Node.js
- Configure GitHub deployment keys
- Deploy application

### 2. Regular Deployments
```bash
# Deploy to staging
./staging-deploy.sh

# Deploy to production (Bahrain)
./production-bh-deploy.sh

# Deploy to production (France)
./production-fr-deploy.sh
```

### 3. Application Updates
```bash
# Update applications on management server
./app-setup.sh
```

## Manual Ansible Commands

For more control, use Ansible directly:

### Syntax Check
```bash
ansible-playbook site.yml --syntax-check
```

### Dry Run (Check Mode)
```bash
ansible-playbook site.yml --check --limit staging-bh
```

### Deploy to Specific Host
```bash
ansible-playbook site.yml --limit staging-bh
```

### Deploy with Verbose Output
```bash
ansible-playbook site.yml --limit production-bh -vv
```

### Deploy Specific Role
```bash
ansible-playbook site.yml --limit staging-bh --tags nginx
```

## Pre-Deployment Checklist

- [ ] Test changes in staging environment first
- [ ] Review playbook changes with `git diff`
- [ ] Run syntax check: `ansible-playbook site.yml --syntax-check`
- [ ] Run in check mode: `ansible-playbook site.yml --check --limit <host>`
- [ ] Verify inventory file is correct
- [ ] Ensure SSH access to target servers
- [ ] Backup critical data if making destructive changes

## Post-Deployment Verification

- [ ] Check service status: `systemctl status nginx`
- [ ] Verify application is running
- [ ] Check Nginx logs: `tail -f /var/log/nginx/error.log`
- [ ] Test SSL certificate: `curl -I https://domain.com`
- [ ] Verify application functionality
- [ ] Monitor server resources

## Rollback Procedure

If deployment fails:
1. Check logs on target server
2. Review Ansible output for errors
3. Fix issues in playbook/role
4. Re-run deployment
5. If critical, manually revert changes on server

## Emergency Procedures

### Restart Services
```bash
# SSH to server
ssh user@server

# Restart Nginx
sudo systemctl restart nginx

# Restart Node.js application
sudo systemctl restart app-name
```

### Check Logs
```bash
# Nginx error log
sudo tail -f /var/log/nginx/error.log

# Application logs
sudo journalctl -u app-name -f
```
