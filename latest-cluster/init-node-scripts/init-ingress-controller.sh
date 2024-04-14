#!/bin/bash

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm fetch ingress-nginx/ingress-nginx --untar

sed -i 's/kind: Deployment/kind: DaemonSet/g' ingress-nginx/values.yaml

helm install main ingress-nginx/. --kubeconfig "/home/ubuntu/.kube/config"
rm -r ingress-nginx