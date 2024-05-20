#!/bin/bash

WORKER_INDEX="$1"
CERT_SHA=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed -e "s/^SHA2-256(stdin)= //")
TOKEN=$(kubeadm token create)

echo "sudo kubeadm join --token $TOKEN cp.sfeir.local:6443 --node-name worker-$WORKER_INDEX --discovery-token-ca-cert-hash sha256:$CERT_SHA -v2"