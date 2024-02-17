#!/bin/bash

CERT_SHA=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed -e "s/^SHA2-256(stdin)= //")
TOKEN=$(kubeadm token create)

echo "sudo kubeadm join --token $TOKEN 18.197.102.140:6443 --discovery-token-ca-cert-hash sha256:$CERT_SHA -v2"