#!/bin/bash

# Install Control Plane
cat << EOF | sudo tee /home/ubuntu/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.28.7
controlPlaneEndpoint: "cp.sfeir.local:6443"
networking:
  podSubnet: 10.0.101.0/24
EOF


# Start Control Plane
sudo kubeadm init --config=/home/ubuntu/kubeadm-config.yaml --node-name=cp-0 --upload-certs | sudo tee /home/ubuntu/kubeadm-init.out

# Setup Kube Config
mkdir -p /home/ubuntu/.kube
chmod 0700 /home/ubuntu/node.key
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config