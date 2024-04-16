#!/bin/bash

SECRET_PATH="my-app"
READ_POLICY_NAME="my-app-reader"
APP_ROLE="my-app"
APP_NAMESPACE="my-app"
SERVICE_ACCOUNT="default"
KUBE_SECRET_NAME="my-secret"

sh /home/ubuntu/init-node-scripts/create-vault-secret.sh $SECRET_PATH $READ_POLICY_NAME $APP_ROLE $APP_NAMESPACE $SERVICE_ACCOUNT $KUBE_SECRET_NAME

# Debug
# kubectl describe vaultstaticsecrets -n my-app vault-static-secret
# kubectl describe vaultauths -n my-app vault-static-auth

# Test:
#apiVersion: v1
#kind: Pod
#metadata:
#  name: pod-with-secret
#spec:
#  containers:
#    - name: nginx
#      image: nginx:1.15.1
#      env:
#        #  kubectl exec -ti pod-with-secret -- env
#        - name: MY_ENV
#          valueFrom:
#            secretKeyRef:
#              name: my-secret
#              key: password