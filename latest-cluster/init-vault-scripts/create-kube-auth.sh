#!/bin/bash

TOKEN_REVIEW_JWT=$0
KUBE_CA_CERT=$1
KUBE_CA_CERT_ISSUER=https://kubernetes.default.svc.cluster.local
VAULT_AUTH_PATH="kubernetes"
VAULT_ADDRESS="http://127.0.0.1:8200"
KUBE_HOST="https://cp.sfeir.local:6443"
ROOT_TOKEN=$(grep "Initial Root Token: " < /home/ubuntu/vault.keys | cut -d ' ' -f 4)

sudo vault login -address=$VAULT_ADDRESS "$ROOT_TOKEN"

sudo vault auth enable -address=$VAULT_ADDRESS -path $VAULT_AUTH_PATH kubernetes
sudo vault write -address=$VAULT_ADDRESS auth/$VAULT_AUTH_PATH/config token_reviewer_jwt="$TOKEN_REVIEW_JWT" kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" issuer="$KUBE_CA_CERT_ISSUER"