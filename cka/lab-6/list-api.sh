#!/bin/bash

SERVER_URL=$(kubectl config view --minify --output jsonpath="{.clusters[*].cluster.server}")

kubectl create serviceaccount test
TOKEN=$(kubectl create token test)

curl "${SERVER_URL}/apis" --header "Authorization: Bearer $TOKEN" -k
curl "${SERVER_URL}/apis/apps/v1" --header "Authorization: Bearer $TOKEN" -k