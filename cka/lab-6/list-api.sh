#!/bin/bash

SERVER_URL=$(kubectl config view --minify --output jsonpath="{.clusters[*].cluster.server}")

TOKEN=$(kubectl create token default)

curl "${SERVER_URL}/apis" --header "Authorization: Bearer $TOKEN" -k
curl "${SERVER_URL}/apis/apps/v1" --header "Authorization: Bearer $TOKEN" -k
curl "${SERVER_URL}/apis/rbac.authorization.k8s.io/v1" --header "Authorization: Bearer $TOKEN" -k