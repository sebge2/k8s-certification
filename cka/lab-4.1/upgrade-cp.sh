#!/bin/bash

# sudo apt-cache madison kubeadm
VERSION="1.28.7-1.1"
KUBE_VERSION="1.28.7"
CP_NODE=$(kubectl get nodes -l  node-role.kubernetes.io/control-plane= -o name)

sudo apt update

sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=$VERSION
sudo apt-mark hold kubeadm

for node in $(kubectl get nodes -o name);
do
  kubectl drain "$node" --ignore-daemonsets
done

sudo kubeadm upgrade plan
sudo kubeadm upgrade apply "v${KUBE_VERSION}"

sudo apt-mark unhold kubectl kubelet
sudo apt-get install -y kubectl=$VERSION kubelet=$VERSION
sudo apt-mark hold kubectl kubelet

sudo systemctl daemon-reload
sudo systemctl restart kubelet

# upgrade other control plane nodes: sudo kubeadm upgrade node

kubectl uncordon "$CP_NODE"

# uncordon other nodes