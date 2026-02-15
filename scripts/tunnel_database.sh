#!/bin/bash
# SSH tunnel to db1bh.boozang.com (AI + staging)
# Connect locally: mongosh mongodb://admin:DevoIsAMongoDatabase@localhost:9999/?authSource=admin
ssh -L 9999:localhost:27017 ubuntu@db1bh.boozang.com
