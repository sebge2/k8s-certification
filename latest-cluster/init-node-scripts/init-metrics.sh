#!/bin/bash

kubectl create -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml --kubeconfig /home/ubuntu/.kube/config

kubectl patch deployment metrics-server -n kube-system --type "json" -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--kubelet-insecure-tls"}]' --kubeconfig /home/ubuntu/.kube/config

# Testing:
# sh /home/ubuntu/init-node-scripts/call-api.sh /apis/metrics.k8s.io/v1beta1/nodes
