# Ansible Best Practices

## Playbook Structure

- **Idempotency**: All tasks should be idempotent - safe to run multiple times
- **Modularity**: Use roles to organize related tasks
- **Variables**: Use `group_vars/` for environment-specific configuration
- **Handlers**: Use handlers for service restarts and reloads

## Role Organization

Each role should follow the standard Ansible directory structure:
```
roles/
└── role_name/
    ├── tasks/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── templates/
    ├── files/
    ├── vars/
    │   └── main.yml
    └── defaults/
        └── main.yml
```

## Naming Conventions

- **Playbooks**: Use descriptive names (e.g., `site.yml`, `apps.yml`)
- **Roles**: Use lowercase with hyphens (e.g., `nginx-wp`, `nodejs`)
- **Variables**: Use snake_case (e.g., `nginx_conf_path`)
- **Tasks**: Use descriptive task names that explain what is being done

## Security Best Practices

- **Vault**: Use Ansible Vault for sensitive data (passwords, API keys)
- **SSH Keys**: Use key-based authentication, never passwords
- **Sudo**: Use `become: yes` only when necessary
- **Permissions**: Set appropriate file permissions (e.g., `mode: '0755'`)

## Testing

- **Syntax Check**: Run `ansible-playbook --syntax-check` before deployment
- **Dry Run**: Use `--check` mode to preview changes
- **Limit**: Test on single host first with `--limit hostname`
- **Verbose**: Use `-v`, `-vv`, or `-vvv` for debugging

## Common Patterns

### Service Management
```yaml
- name: Restart nginx
  systemd:
    name: nginx
    state: restarted
    enabled: yes
```

### File Templates
```yaml
- name: Deploy configuration
  template:
    src: config.j2
    dest: /etc/app/config.conf
    mode: '0644'
  notify: restart service
```

### Git Repository
```yaml
- name: Clone repository
  git:
    repo: https://github.com/user/repo.git
    dest: /var/www/app
    version: main
```

## Error Handling

- Use `failed_when` to define custom failure conditions
- Use `ignore_errors: yes` sparingly and only when appropriate
- Always check return codes and output for critical tasks
