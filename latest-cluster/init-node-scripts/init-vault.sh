#!/bin/bash

# https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

APP_NAMESPACE="my-app"
APP_ROLE="my-app-reader"
SECRET_PATH="my-app"

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
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
        mount: kubernetes
        keyName: vso-client-cache
        transitMount: auth-role-operator-transit
        kubernetes:
          role: auth-role-operator
          serviceAccount: auth-role-operator
EOF

CA_CERT=$(kubectl get cm kube-root-ca.crt -o jsonpath="{['data']['ca\.crt']}" --kubeconfig /home/ubuntu/.kube/config)
ssh -o StrictHostKeyChecking=no -i /home/ubuntu/node.key "ubuntu@vault.sfeir.local" "sh /home/ubuntu/init-vault-scripts/bind-vault-kube.sh \"${CA_CERT}\""

kubectl create ns my-app --kubeconfig /home/ubuntu/.kube/config

kubectl --kubeconfig /home/ubuntu/.kube/config apply -f -<<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: static-auth
  namespace: $APP_NAMESPACE
spec:
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: $APP_ROLE
    serviceAccount: default
    audiences:
      - vault
EOF

kubectl --kubeconfig /home/ubuntu/.kube/config apply -f -<<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: vault-kv-app
  namespace: $APP_NAMESPACE
spec:
  type: kv-v2
  mount: kvv2
  path: $SECRET_PATH
  destination:
    name: secretkv
    create: true
  refreshAfter: 30s
  vaultAuthRef: static-auth
EOF

# Debug
# kubectl describe vaultstaticsecrets -n my-app vault-kv-app
# kubectl describe vaultauths -n my-app