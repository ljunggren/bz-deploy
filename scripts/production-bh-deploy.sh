#!/bin/bash
cd "$(dirname "$0")/.."
ansible-playbook -i inventories/production-bh site.yml --tags=deploy
