#!/bin/bash
cd "$(dirname "$0")/.."
ansible-playbook -i inventories/db-fr database.yml
