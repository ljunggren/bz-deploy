#!/bin/bash
# Upgrade Node.js on eu server (production-fr)
# Run AFTER staging is verified

echo "=== Node.js Upgrade: production-fr (eu server) ==="
echo "Target: Node.js v24.13.0"
echo ""
echo "WARNING: This is a PRODUCTION server!"
echo "Make sure staging upgrade was successful first."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

ansible-playbook -i inventories/production-fr nodejs-upgrade.yml
