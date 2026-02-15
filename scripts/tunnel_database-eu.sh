#!/bin/bash
# SSH tunnel to db1fr.boozang.com (EU)
# Connect locally: mongosh mongodb://admin:DevoIsAMongoDatabase@localhost:10999/?authSource=admin
ssh -L 10999:localhost:27017 ubuntu@db1fr.boozang.com
