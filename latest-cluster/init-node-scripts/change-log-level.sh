#!/bin/bash

# First argument is the component: apiserver
# https://nakamasato.medium.com/how-to-change-log-level-of-kubernetes-components-3cd0e15b86ea

kubectl --kubeconfig /home/ubuntu/.kube/config apply -f -<<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: change-logging-level
rules:
- apiGroups:
  - ""
  resources:
  - nodes/proxy
  verbs:
  - update
- nonResourceURLs:
  - /debug/flags/v
  verbs:
  - put

---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: change-logging-level
  namespace: kube-system

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: change-logging-level
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: change-logging-level
subjects:
- kind: ServiceAccount
  name: change-logging-level
  namespace: kube-system
EOF

TOKEN=$(kubectl create token change-logging-level -n kube-system)

if [ "$1" = "apiserver" ]; then
  curl -s -X PUT -d '5' https://cp.sfeir.local:6443/debug/flags/v --header "Authorization: Bearer $TOKEN" -k -v
fi