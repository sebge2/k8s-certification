#!/bin/bash

curl --cert ~/.minikube/profiles/minikube/client.crt --key ~/.minikube/profiles/minikube/client.key --cacert ~/.minikube/ca.crt https://127.0.0.1:57894/api/v1/pods