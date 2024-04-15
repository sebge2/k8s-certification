#!/bin/bash

VAULT_ADDRESS="http://127.0.0.1:8200"
SECRET_PATH="my-app"

sudo apt-get update && sudo apt-get install gpg wget
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install vault

sudo tee /etc/vault.d/vault.hcl <<EOF
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

# Full configuration options can be found at https://developer.hashicorp.com/vault/docs/configuration

ui = true
api_addr  = "http://127.0.0.1:8200"
log_level = "debug"

storage "file" {
  path = "/opt/vault/data"
}

# HTTP listener
listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}
EOF

sudo systemctl enable vault.service
sudo systemctl start vault.service
# logs: journalctl -xeu vault.service

sleep 30

sudo vault operator init -address=$VAULT_ADDRESS | sudo tee -a /home/ubuntu/vault.keys

UNSEAL_KEY_1=$(grep "Unseal Key 1: " < /home/ubuntu/vault.keys | cut -d ' ' -f 4)
UNSEAL_KEY_2=$(grep "Unseal Key 2: " < /home/ubuntu/vault.keys | cut -d ' ' -f 4)
UNSEAL_KEY_3=$(grep "Unseal Key 3: " < /home/ubuntu/vault.keys | cut -d ' ' -f 4)
ROOT_TOKEN=$(grep "Initial Root Token: " < /home/ubuntu/vault.keys | cut -d ' ' -f 4)

sudo vault operator unseal -address=$VAULT_ADDRESS "$UNSEAL_KEY_1"
sudo vault operator unseal -address=$VAULT_ADDRESS "$UNSEAL_KEY_2"
sudo vault operator unseal -address=$VAULT_ADDRESS "$UNSEAL_KEY_3"

sudo vault login -address=$VAULT_ADDRESS "$ROOT_TOKEN"
sudo vault secrets enable -address=$VAULT_ADDRESS -path=kvv2 kv-v2

# Example
sudo vault kv put -address=$VAULT_ADDRESS "kvv2/$SECRET_PATH" username="static-user" password="static-password"