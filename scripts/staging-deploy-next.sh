#!/bin/bash
cd "$(dirname "$0")/.."
ansible-playbook -i inventories/staging-bh-next site.yml --tags=deploy
