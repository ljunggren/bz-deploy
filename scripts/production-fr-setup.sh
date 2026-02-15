#!/bin/bash
cd "$(dirname "$0")/.."
ansible-playbook -i inventories/production-fr site.yml
