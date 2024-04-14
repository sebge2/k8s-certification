#!/bin/bash

mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/init-scripts
sleep 120

mv /home/ubuntu/init-*.sh /home/ubuntu/init-scripts/
mv /home/ubuntu/setup-*.sh /home/ubuntu/init-scripts/
mv /home/ubuntu/join-command-helper.sh /home/ubuntu/init-scripts/
sh -x /home/ubuntu/init-scripts/init-kube.sh >> /home/ubuntu/logs/init-kube.log 2>&1
sh -x /home/ubuntu/init-scripts/init-containerd.sh >> /home/ubuntu/logs/init-containerd.log 2>&1
sh -x /home/ubuntu/init-scripts/init-system.sh >> /home/ubuntu/logs/init-system.log 2>&1
sh -x /home/ubuntu/init-scripts/init-nfs-client.sh >> /home/ubuntu/logs/init-nfs-client.log 2>&1