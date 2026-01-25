# bz-deploy Project Context

## Overview
bz-deploy is an Ansible-based deployment infrastructure for the Boozang test automation platform. It manages server provisioning, configuration, and application deployment across multiple environments (staging, production).

## Tech Stack
- **Infrastructure as Code**: Ansible playbooks and roles
- **Target OS**: Ubuntu 22.04 LTS
- **Web Server**: Nginx with Let's Encrypt SSL
- **Application Runtime**: Node.js
- **Version Control**: GitHub integration for automated deployments
- **Additional Services**: PHP, MySQL, WordPress (for management server)

## Deployment Environments

### Staging
- **staging-bh**: Bahrain staging server
- **staging-bh-next**: Next-generation staging environment

### Production
- **production-bh**: Bahrain production server
- **production-fr**: France production server

### Management
- **management-bh**: WordPress-based management server

## Core Concepts

### Playbooks
- **site.yml**: Main deployment playbook for Node.js applications
- **apps.yml**: Application-specific setup (repositories, Nginx configs)

### Roles
Modular Ansible roles for different components:
- `setup` - Base system configuration
- `nginx` - Web server setup
- `https` - Let's Encrypt SSL certificates
- `nodejs` - Node.js runtime installation
- `github` - GitHub integration and deployment keys
- `application` - Application deployment and configuration
- `nginx-wp` - WordPress-specific Nginx configuration
- `php`, `mysql`, `wordpress` - WordPress stack

### Inventory Structure
- `inventories/` - Environment-specific inventory files
- `group_vars/` - Group-level variables and configuration

## Deployment Scripts

Deployment scripts follow a naming pattern: `{environment}-{action}.sh`

Examples:
- `staging-setup.sh` - Initial staging environment setup
- `staging-deploy.sh` - Deploy to staging
- `production-bh-setup.sh` - Setup Bahrain production
- `production-bh-deploy.sh` - Deploy to Bahrain production

## Key Patterns

### Idempotent Deployments
All Ansible playbooks are designed to be idempotent - safe to run multiple times without side effects.

### Role-Based Organization
Infrastructure components are separated into reusable roles that can be composed for different server types.

### Environment Isolation
Each environment has its own inventory file and can have environment-specific variables in `group_vars/`.
