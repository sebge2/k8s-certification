#!/bin/bash

# sudo apt-cache madison kubeadm
VERSION="1.28.7-1.1"

sudo apt update
sudo apt-mark unhold kubeadm
sudo apt-get install -y kubeadm=$VERSION
sudo apt-mark hold kubeadm

sudo kubeadm upgrade node

sudo apt-mark unhold kubectl kubelet
sudo apt-get install -y kubectl=$VERSION kubelet=$VERSION
sudo apt-mark hold kubectl kubelet

sudo systemctl daemon-reload
sudo systemctl restart kubelet