#!/bin/bash

mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/init-node-scripts
sleep 120

mv /home/ubuntu/*.sh /home/ubuntu/init-node-scripts/
sh -x /home/ubuntu/init-node-scripts/init-kube.sh >> /home/ubuntu/logs/init-kube.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-containerd.sh >> /home/ubuntu/logs/init-containerd.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-system.sh >> /home/ubuntu/logs/init-system.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-nfs-client.sh >> /home/ubuntu/logs/init-nfs-client.log 2>&1