#!/bin/bash

# Install Cilium
helm repo add cilium https://helm.cilium.io/
helm repo update
helm template cilium cilium/cilium --version 1.14.1 --namespace kube-system > /home/ubuntu/cilium.yaml
kubectl apply -f /home/ubuntu/cilium.yaml