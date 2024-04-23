#!/bin/bash

NAMESPACE="kubernetes-dashboard"

# https://github.com/kubernetes/dashboard/blob/master/docs/user/access-control/creating-sample-user.md
# https://www.kerno.io/learn/kubernetes-dashboard-deploy-visualize-cluster
# https://artifacthub.io/packages/helm/k8s-dashboard/kubernetes-dashboard

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace $NAMESPACE --set "kong.proxy.type=NodePort" --set "kong.proxy.http.enabled=true" --kubeconfig "/home/ubuntu/.kube/config"
kubectl patch service kubernetes-dashboard-kong-proxy --kubeconfig /home/ubuntu/.kube/config --namespace $NAMESPACE --type='json' -p '[{"op": "replace", "path": "/spec/ports/1/nodePort", "value": 31503}]'


kubectl --kubeconfig /home/ubuntu/.kube/config apply -f -<<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: $NAMESPACE

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: $NAMESPACE

---

apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"
type: kubernetes.io/service-account-token
EOF

TOKEN=$(kubectl get secret admin-user -n $NAMESPACE -o jsonpath={".data.token"} --kubeconfig /home/ubuntu/.kube/config | base64 -d)
echo "Dashboard Token:"
echo "$TOKEN"

# Test it:
# curl -k -H "Authorization: Bearer ${TOKEN}" https://cp.sfeir.local:6443/api/v1/