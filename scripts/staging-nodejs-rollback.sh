#!/bin/bash
cd "$(dirname "$0")/.."
# Rollback Node.js on staging server

echo "=== Node.js Rollback: staging-bh ==="
echo "Rolling back to Node.js v20.x"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

ansible-playbook -i inventories/staging-bh nodejs-rollback.yml
