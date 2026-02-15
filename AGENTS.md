# AI Agent Quick Reference

> **For AI Agents**: Read [.agent/instructions.md](./.agent/instructions.md) for complete operational guidelines.

## Quick Start

1. **Context**: Review `.agent/context/project-context.md` and `.agent/context/infrastructure.md`
2. **Instructions**: Read `.agent/instructions.md` for all operational rules
3. **History**: Check `.agent/memory/journal.md` for recent work

## Key Guidelines

- **Deployment**: Always test in staging before production
- **Ansible**: Follow idempotent patterns, use roles for modularity
- **Scripts**: Use deployment scripts in `scripts/` (`scripts/staging-deploy.sh`, `scripts/production-bh-deploy.sh`, etc.)
- **Verification**: Check service status and logs after deployments
- **Security**: Never commit credentials or private keys

## Common Tasks

### Deploy to Staging
```bash
scripts/staging-deploy.sh
```

### Deploy to Production
```bash
# Bahrain
scripts/production-bh-deploy.sh

# France
scripts/production-fr-deploy.sh
```

### Syntax Check
```bash
ansible-playbook site.yml --syntax-check
```

### Dry Run
```bash
ansible-playbook site.yml --check --limit staging-bh
```

## Session Commands

- `start session` - Initialize session, review context
- `journal` - Update work log and instructions
- `push` - Commit and push changes
- `pull` - Pull latest changes

## Documentation

See `.agent/instructions/` for detailed guides on:
- Ansible best practices
- Deployment workflows
- Documentation standards
