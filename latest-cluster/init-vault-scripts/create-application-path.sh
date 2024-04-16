#!/bin/bash

SECRET_PATH="$1"
READ_POLICY_NAME="$2"
APP_ROLE="$3"
APP_NAMESPACE="$4"
SERVICE_ACCOUNT="$5"

VAULT_AUTH_PATH="kubernetes"
VAULT_ADDRESS="http://127.0.0.1:8200"
ROOT_TOKEN=$(grep "Initial Root Token: " < /home/ubuntu/vault.keys | cut -d ' ' -f 4)

sudo vault login -address="$VAULT_ADDRESS" "$ROOT_TOKEN"

echo "path \"kvv2/data/$SECRET_PATH\" {\n capabilities = [\"read\"]\n}"  | sudo vault policy write -address="$VAULT_ADDRESS" "$READ_POLICY_NAME"  -

sudo vault write -address="$VAULT_ADDRESS" "auth/$VAULT_AUTH_PATH/role/$APP_ROLE" bound_service_account_names="$SERVICE_ACCOUNT" bound_service_account_namespaces="$APP_NAMESPACE" policies="$READ_POLICY_NAME" audience=vault ttl=24h

sudo vault kv put -address="$VAULT_ADDRESS" "kvv2/$SECRET_PATH" example="john.doe"