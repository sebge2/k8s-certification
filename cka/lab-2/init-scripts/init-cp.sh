#!/bin/bash

# Install Control Pane
PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
cat << EOF | sudo tee /home/ubuntu/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.28.7
controlPlaneEndpoint: "${PUBLIC_IP}:6443"
networking:
  podSubnet: 10.0.101.0/24
EOF


# Start Control Pane
sudo kubeadm init --config=/home/ubuntu/kubeadm-config.yaml --upload-certs | sudo tee /home/ubuntu/kubeadm-init.out


# Setup Kube Config
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config