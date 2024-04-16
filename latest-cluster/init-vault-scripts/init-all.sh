#!/bin/bash

mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/init-vault-scripts

sleep 60

mv /home/ubuntu/init-*.sh /home/ubuntu/init-vault-scripts/
mv /home/ubuntu/create-kube-auth.sh /home/ubuntu/init-vault-scripts/
mv /home/ubuntu/create-role.sh /home/ubuntu/init-vault-scripts/

sh -x /home/ubuntu/init-vault-scripts/init-vault.sh >> /home/ubuntu/logs/init-vault.log 2>&1