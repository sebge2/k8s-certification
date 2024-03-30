#!/bin/bash

mkdir -p /home/ubuntu/logs
sleep 60

sh -x /home/ubuntu/init-kube.sh >> /home/ubuntu/logs/init-kube.log 2>&1
sh -x /home/ubuntu/init-containerd.sh >> /home/ubuntu/logs/init-containerd.log 2>&1
sh -x /home/ubuntu/init-system.sh >> /home/ubuntu/logs/init-system.log 2>&1
sh -x /home/ubuntu/init-cp.sh >> /home/ubuntu/logs/init-cp.log 2>&1
sh -x /home/ubuntu/init-helm.sh >> /home/ubuntu/logs/init-helm.log 2>&1
sh -x /home/ubuntu/init-cp-tools.sh >> /home/ubuntu/logs/init-cp-tools.log 2>&1
sh -x /home/ubuntu/init-nfs-server.sh >> /home/ubuntu/logs/init-nfs-server.log 2>&1

sleep 120
sh -x /home/ubuntu/init-cilium.sh >> /home/ubuntu/logs/init-cilium.log 2>&1
sh -x /home/ubuntu/init-worker-join.sh ${numberWorkerNodes} >> /home/ubuntu/logs/init-worker-join.log 2>&1