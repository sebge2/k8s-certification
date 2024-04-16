#!/bin/bash

mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/init-vault-scripts

sleep 60

mv /home/ubuntu/*.sh /home/ubuntu/init-vault-scripts/

sh -x /home/ubuntu/init-vault-scripts/init-vault.sh >> /home/ubuntu/logs/init-vault.log 2>&1