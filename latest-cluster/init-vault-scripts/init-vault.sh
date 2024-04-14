#!/bin/bash

VAULT_ADDRESS="http://127.0.0.1:8200"

sudo apt-get update && sudo apt-get install gpg wget
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update && sudo apt-get install vault

sudo vault server -dev -dev-listen-address="0.0.0.0:8200"  &

sleep 30

sudo vault secrets enable -address=$VAULT_ADDRESS -path=kvv2 kv-v2
