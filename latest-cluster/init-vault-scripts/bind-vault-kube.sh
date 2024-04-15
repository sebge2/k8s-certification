#!/bin/bash

VAULT_AUTH_PATH="kubernetes"
VAULT_ADDRESS="http://127.0.0.1:8200"
KUBE_HOST="https://cp.sfeir.local:6443"
READ_POLICY_NAME="my-app-reader"
APP_ROLE="my-app-reader"
APP_NAMESPACE="my-app"
ROOT_TOKEN=$(grep "Initial Root Token: " < /home/ubuntu/vault.keys | cut -d ' ' -f 4)

sudo vault login -address=$VAULT_ADDRESS "$ROOT_TOKEN"

sudo vault auth enable -address=$VAULT_ADDRESS -path $VAULT_AUTH_PATH kubernetes
sudo vault write -address=$VAULT_ADDRESS auth/$VAULT_AUTH_PATH/config kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$0"

echo "path \"kvv2/*\" {\n capabilities = [\"read\", \"list\"]\n}"  | sudo vault policy write -address="$VAULT_ADDRESS" "$READ_POLICY_NAME"  -
sudo vault write -address=$VAULT_ADDRESS "auth/$VAULT_AUTH_PATH/role/$APP_ROLE" bound_service_account_names=default bound_service_account_namespaces="$APP_NAMESPACE" policies="$READ_POLICY_NAME" audience=vault ttl=24h