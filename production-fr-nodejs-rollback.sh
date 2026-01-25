#!/bin/bash
# Rollback Node.js on eu server (production-fr)

echo "=== Node.js Rollback: production-fr (eu server) ==="
echo "Rolling back to Node.js v20.x"
echo ""
echo "WARNING: This is a PRODUCTION server!"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

ansible-playbook -i inventories/production-fr nodejs-rollback.yml
