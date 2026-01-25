# Documentation

## README Requirements

- **Project Overview**: Always include a clear description of what the project does
- **Prerequisites**: List all required software and versions
- **Setup Instructions**: Provide step-by-step setup guide
- **Usage**: Document how to use deployment scripts
- **Directory Structure**: Explain the organization of playbooks, roles, and inventories
- **Contributing**: Include guidelines for contributing to the project

## Ansible Documentation

- **Playbooks**: Document purpose and usage at the top of each playbook
- **Roles**: Include README.md in each role directory explaining:
  - Purpose of the role
  - Variables that can be configured
  - Dependencies on other roles
  - Example usage
- **Variables**: Document all variables in `defaults/main.yml` with comments

## Diagrams

- Use Mermaid for architecture diagrams and deployment flows
- Include network topology diagrams for complex setups
- Document service dependencies

## Comments

- Add comments to complex tasks explaining why, not what
- Document any workarounds or non-obvious solutions
- Include links to relevant documentation or issues

## Changelog

- Maintain a CHANGELOG.md for significant changes
- Use semantic versioning for releases
- Document breaking changes clearly
