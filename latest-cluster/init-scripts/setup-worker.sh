#!/bin/bash

mkdir -p /home/ubuntu/logs
sleep 120

sh -x /home/ubuntu/init-scripts/init-kube.sh >> /home/ubuntu/logs/init-kube.log 2>&1
sh -x /home/ubuntu/init-scripts/init-containerd.sh >> /home/ubuntu/logs/init-containerd.log 2>&1
sh -x /home/ubuntu/init-scripts/init-system.sh >> /home/ubuntu/logs/init-system.log 2>&1
sh -x /home/ubuntu/init-scripts/init-nfs-client.sh >> /home/ubuntu/logs/init-nfs-client.log 2>&1