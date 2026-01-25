# Boozang Deployment Infrastructure

> **For Claude/AI Assistants**: See [AGENTS.md](./AGENTS.md) for AI-specific quick reference.

This repository contains Ansible playbooks and roles for deploying the Boozang test automation platform across multiple environments.

## Overview

bz-deploy manages infrastructure as code for:
- **Staging environments**: Testing and validation
- **Production servers**: Bahrain and France regions
- **Management server**: WordPress-based documentation and tools

## Tech Stack

- **Infrastructure**: Ansible (Ubuntu 22.04 LTS)
- **Web Server**: Nginx with Let's Encrypt SSL
- **Runtime**: Node.js
- **Additional**: PHP, MySQL, WordPress (management server)

## Quick Start

### Prerequisites
- Ansible installed locally
- SSH access to target servers
- GitHub deployment keys configured

### Deploy to Staging
```bash
./staging-deploy.sh
```

### Deploy to Production
```bash
# Bahrain
./production-bh-deploy.sh

# France  
./production-fr-deploy.sh
```

## Project Structure

```
bz-deploy/
├── .agent/              # AI agent instructions and context
├── inventories/         # Environment-specific inventory files
├── group_vars/          # Group-level variables
├── roles/               # Ansible roles
│   ├── setup/          # Base system configuration
│   ├── nginx/          # Web server setup
│   ├── https/          # SSL certificates
│   ├── nodejs/         # Node.js runtime
│   ├── github/         # GitHub integration
│   └── application/    # App deployment
├── site.yml            # Main deployment playbook
├── apps.yml            # Application-specific setup
└── *.sh                # Deployment scripts
```

## Environments

### Staging
- **staging-bh**: Bahrain staging server
- **staging-bh-next**: Next-generation staging

### Production
- **production-bh**: Bahrain production
- **production-fr**: France production

### Management
- **management-bh**: WordPress management server

## Deployment Workflow

1. **Test in Staging**
   ```bash
   ./staging-deploy.sh
   ```

2. **Verify Changes**
   - Check service status
   - Review logs
   - Test functionality

3. **Deploy to Production**
   ```bash
   ./production-bh-deploy.sh
   ```

## Manual Ansible Commands

### Syntax Check
```bash
ansible-playbook site.yml --syntax-check
```

### Dry Run
```bash
ansible-playbook site.yml --check --limit staging-bh
```

### Deploy to Specific Host
```bash
ansible-playbook site.yml --limit production-bh
```

### Verbose Output
```bash
ansible-playbook site.yml --limit staging-bh -vv
```

## Documentation

- **[.agent/instructions.md](./.agent/instructions.md)**: Complete operational guidelines
- **[.agent/context/project-context.md](./.agent/context/project-context.md)**: Project architecture
- **[.agent/context/infrastructure.md](./.agent/context/infrastructure.md)**: Server details
- **[.agent/instructions/deployment.md](./.agent/instructions/deployment.md)**: Deployment procedures
- **[.agent/instructions/ansible.md](./.agent/instructions/ansible.md)**: Ansible best practices

## Support

For deployment issues or questions, refer to:
- `.agent/memory/deployment-log.md` - Deployment history
- `.agent/memory/journal.md` - Recent work and decisions

## License

[Add license information]
