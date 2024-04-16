#!/bin/bash

SECRET_PATH="my-app"
READ_POLICY_NAME="my-app-reader"
APP_ROLE="my-app"
APP_NAMESPACE="my-app"
SERVICE_ACCOUNT="default"
KUBE_SECRET_NAME="my-secret"

sh /home/ubuntu/init-node-scripts/create-vault-secret.sh $SECRET_PATH $READ_POLICY_NAME $APP_ROLE $APP_NAMESPACE $SERVICE_ACCOUNT $KUBE_SECRET_NAME