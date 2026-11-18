#!/bin/bash
cd "$(dirname "$0")/.."
# Deploy a named release:  production-fr-deploy.sh v11.2.4
# With no argument, deploys the tip of bz-dist master.
RELEASE_ARG=""
[ -n "$1" ] && RELEASE_ARG="-e release=$1"
ansible-playbook -i inventories/production-fr site.yml --tags=deploy $RELEASE_ARG
