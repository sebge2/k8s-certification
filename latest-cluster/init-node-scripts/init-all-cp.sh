#!/bin/bash

mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/init-node-scripts

sleep 60

mv /home/ubuntu/*.sh /home/ubuntu/init-node-scripts/
sh -x /home/ubuntu/init-node-scripts/init-kube.sh >> /home/ubuntu/logs/init-kube.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-containerd.sh >> /home/ubuntu/logs/init-containerd.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-system.sh >> /home/ubuntu/logs/init-system.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-cp.sh >> /home/ubuntu/logs/init-cp.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-helm.sh >> /home/ubuntu/logs/init-helm.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-cp-tools.sh >> /home/ubuntu/logs/init-cp-tools.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-nfs-server.sh >> /home/ubuntu/logs/init-nfs-server.log 2>&1

sleep 120
sh -x /home/ubuntu/init-node-scripts/init-cilium.sh >> /home/ubuntu/logs/init-cilium.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-worker-join.sh ${numberWorkerNodes} >> /home/ubuntu/logs/init-worker-join.log 2>&1

sh -x /home/ubuntu/init-node-scripts/init-ingress-controller.sh >> /home/ubuntu/logs/init-ingress-controller.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-service-mesh.sh >> /home/ubuntu/logs/init-service-mesh.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-vault.sh >> /home/ubuntu/logs/init-vault.log 2>&1
sh -x /home/ubuntu/init-node-scripts/init-sample-vault-secret.sh>> /home/ubuntu/logs/init-sample-vault-secret.log 2>&1