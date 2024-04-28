#!/bin/bash

NAMESPACE="monitoring"

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus-stack  prometheus-community/kube-prometheus-stack --namespace $NAMESPACE --kubeconfig "/home/ubuntu/.kube/config" --set "grafana.service.type=NodePort" --set "grafana.service.nodePort=31504"

ADMIN_PWD=$(kubectl get secret prometheus-stack-grafana  -o jsonpath="{.data.admin-password}" --kubeconfig /home/ubuntu/.kube/config --namespace $NAMESPACE  | base64 --decode ; echo)
echo "Admin password:"
echo "$ADMIN_PWD"