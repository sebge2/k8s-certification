#!/bin/bash

NAMESPACE="logging"

kubectl create ns $NAMESPACE --kubeconfig /home/ubuntu/.kube/config

helm repo add elastic https://helm.elastic.co
helm repo update
helm install elasticsearch elastic/elasticsearch --namespace=$NAMESPACE --kubeconfig "/home/ubuntu/.kube/config"  -f -<<EOF
service:
  nodePort: 31501
  type: NodePort
replicas: 1
persistence:
  enabled: false
protocol: http
extraEnvs:
  - name: 'xpack.security.enabled'
    value: 'false'
EOF

ELASTIC_TOKEN=$(kubectl get secrets --namespace=logging elasticsearch-master-credentials -ojsonpath='{.data.password}' --kubeconfig /home/ubuntu/.kube/config | base64 -d)
echo "Elastic Token:"
echo "$ELASTIC_TOKEN"


#helm install kibana elastic/kibana --namespace=$NAMESPACE --kubeconfig "/home/ubuntu/.kube/config" --set "service.nodePort=31502" --set "service.type=NodePort"
#helm install fluentd stable/fluentd-elasticsearch --namespace=$NAMESPACE --kubeconfig "/home/ubuntu/.kube/config"

# Kibana:
#kubectl port-forward --namespace logging $POD_NAME 5601:5601

# Elastic Search
#kubectl port-forward --namespace logging $POD_NAME 9200:9200