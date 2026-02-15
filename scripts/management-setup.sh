#!/bin/bash
cd "$(dirname "$0")/.."
ansible-playbook -i inventories/management-bh site.yml
