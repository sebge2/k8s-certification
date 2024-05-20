#!/bin/bash

CP_INDEX="$1"
CERTIFICATE_KEY="$2"

CERT_SHA=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed -e "s/^SHA2-256(stdin)= //")
TOKEN=$(kubeadm token create)

echo "sudo kubeadm join --control-plane --token $TOKEN cp-0.sfeir.local:6443 --node-name cp-$CP_INDEX --discovery-token-ca-cert-hash sha256:$CERT_SHA --certificate-key $CERTIFICATE_KEY -v2"
