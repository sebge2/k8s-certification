#!/bin/bash

echo "Can I create deployments in default namespace?"
kubectl auth can-i create deployments

echo "Can Bob create deployments in default namespace?"
kubectl auth can-i create deployments --as bob

echo "Can Bob create deployments in developer namespace?"
kubectl auth can-i create deployments --as bob --namespace developer

