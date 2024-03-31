#!/bin/bash

# Install Cilium
helm repo add cilium https://helm.cilium.io/
helm repo update

helm template cilium cilium/cilium --version 1.14.1 --namespace kube-system --set routing-mode=native --set ipv4-native-routing-cidr=192.168.128.0/24 > /home/ubuntu/cilium.yaml
kubectl --kubeconfig /home/ubuntu/.kube/config apply -f /home/ubuntu/cilium.yaml