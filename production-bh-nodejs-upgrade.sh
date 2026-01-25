#!/bin/bash
# Upgrade Node.js on ai server (production-bh)
# Run LAST after staging and eu are verified

echo "=== Node.js Upgrade: production-bh (ai server) ==="
echo "Target: Node.js v24.13.0"
echo ""
echo "WARNING: This is the PRIMARY PRODUCTION server!"
echo "Make sure staging AND eu server upgrades were successful first."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

ansible-playbook -i inventories/production-bh nodejs-upgrade.yml
