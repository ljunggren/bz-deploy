#!/bin/bash
cd "$(dirname "$0")/.."
# Upgrade Node.js on staging server
# Run this FIRST before production servers

echo "=== Node.js Upgrade: staging-bh ==="
echo "Target: Node.js v24.13.0"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

ansible-playbook -i inventories/staging-bh nodejs-upgrade.yml
