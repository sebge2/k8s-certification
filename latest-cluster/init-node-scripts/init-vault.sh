#!/bin/bash

# https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-external-vault
# https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

VAULT_NAMESPACE="vault"
VAULT_AUTH_PATH="kubernetes"

kubectl --kubeconfig /home/ubuntu/.kube/config create ns $VAULT_NAMESPACE

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
helm install vault hashicorp/vault --create-namespace --namespace $VAULT_NAMESPACE --set "global.externalVaultAddr=http://vault.sfeir.local:8200"

SECRET_NAME=$(kubectl get secrets -n $VAULT_NAMESPACE --output=json | jq -r '.items[].metadata | select(.name|startswith("vault-token-")).name')
TOKEN_REVIEW_JWT=$(kubectl get secret "$SECRET_NAME" -n $VAULT_NAMESPACE --output='go-template={{ .data.token }}' | base64 --decode)
KUBE_CA_CERT=$(cat /etc/kubernetes/pki/apiserver.crt)

ssh -o StrictHostKeyChecking=no -i /home/ubuntu/node.key "ubuntu@vault.sfeir.local" "sh /home/ubuntu/init-vault-scripts/create-kube-auth.sh \"${TOKEN_REVIEW_JWT}\" \"${KUBE_CA_CERT}\""

kubectl --kubeconfig /home/ubuntu/.kube/config apply -f -<<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $SECRET_NAME
  namespace: $VAULT_NAMESPACE
  annotations:
    kubernetes.io/service-account.name: vault
type: kubernetes.io/service-account-token
EOF

helm install vault-secrets-operator hashicorp/vault-secrets-operator -n vault-secrets-operator-system --create-namespace --kubeconfig "/home/ubuntu/.kube/config" -f -<<EOF
defaultVaultConnection:
  enabled: true
  address: "http://vault.sfeir.local:8200"
  skipTLSVerify: false
controller:
  manager:
    clientCache:
      persistenceModel: direct-encrypted
      storageEncryption:
        enabled: true
        mount: $VAULT_AUTH_PATH
        keyName: vso-client-cache
        transitMount: auth-role-operator-transit
        kubernetes:
          role: auth-role-operator
          serviceAccount: auth-role-operator
EOF