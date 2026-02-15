#!/bin/bash
cd "$(dirname "$0")/.."
ansible-playbook -i inventories/staging-bh site.yml --tags=deploy
