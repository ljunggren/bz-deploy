#!/bin/bash
cd "$(dirname "$0")/.."
ansible-playbook -i inventories/db-bh database.yml
