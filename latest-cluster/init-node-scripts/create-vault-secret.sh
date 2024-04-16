#!/bin/bash

SECRET_PATH="$1"
READ_POLICY_NAME="$2"
APP_ROLE="$3"
APP_NAMESPACE="$4"
SERVICE_ACCOUNT="$5"
KUBE_SECRET_NAME="$6"
VAULT_AUTH_PATH="kubernetes"

ssh -o StrictHostKeyChecking=no -i /home/ubuntu/node.key "ubuntu@vault.sfeir.local" "sh /home/ubuntu/init-vault-scripts/create-application-path.sh \"${SECRET_PATH}\" \"${READ_POLICY_NAME}\" \"${APP_ROLE}\" \"${APP_NAMESPACE}\" \"${SERVICE_ACCOUNT}\""

kubectl --kubeconfig /home/ubuntu/.kube/config create ns "$APP_NAMESPACE"

kubectl --kubeconfig /home/ubuntu/.kube/config apply -f -<<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: vault-static-auth
  namespace: $APP_NAMESPACE
spec:
  method: kubernetes
  mount: $VAULT_AUTH_PATH
  kubernetes:
    role: $APP_ROLE
    serviceAccount: $SERVICE_ACCOUNT
    audiences:
      - vault
EOF

kubectl --kubeconfig /home/ubuntu/.kube/config apply -f -<<EOF
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: vault-static-secret
  namespace: $APP_NAMESPACE
spec:
  vaultAuthRef: vault-static-auth
  mount: kvv2
  type: kv-v2
  path:  $SECRET_PATH
  refreshAfter: 10s
  destination:
    create: true
    name: $KUBE_SECRET_NAME
EOF