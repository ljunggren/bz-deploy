#!/bin/bash
# Rollback Node.js on ai server (production-bh)

echo "=== Node.js Rollback: production-bh (ai server) ==="
echo "Rolling back to Node.js v20.x"
echo ""
echo "WARNING: This is the PRIMARY PRODUCTION server!"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

ansible-playbook -i inventories/production-bh nodejs-rollback.yml
