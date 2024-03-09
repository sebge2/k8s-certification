#!/bin/bash

kubectl delete pod busybox 2&> /dev/null

echo "CA:"
kubectl run -it -t busybox --image=busybox --restart=Never -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
kubectl delete pod busybox 2&> /dev/null

echo ""

echo "Token:"
kubectl run -it -t busybox --image=busybox --restart=Never -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
kubectl delete pod busybox 2&> /dev/null
