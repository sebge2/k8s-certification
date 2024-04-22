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
protocol: https
extraEnvs:
  - name: 'xpack.security.http.ssl.enabled'
    value: 'true'
EOF

ELASTIC_TOKEN=$(kubectl get secrets --namespace=logging elasticsearch-master-credentials -ojsonpath='{.data.password}' --kubeconfig /home/ubuntu/.kube/config | base64 -d)
echo "Elastic Password for 'elastic' user:"
echo "$ELASTIC_TOKEN"


helm install kibana elastic/kibana --namespace=$NAMESPACE --kubeconfig "/home/ubuntu/.kube/config" -f -<<EOF
service:
  nodePort: 31502
  type: NodePort
EOF

USER_PWD=$(kubectl get secrets --namespace=logging elasticsearch-master-credentials -ojsonpath='{.data.password}' --kubeconfig /home/ubuntu/.kube/config | base64 -d)
echo "Kibana Password for 'elastic' user:"
echo "$USER_PWD"


#helm install fluentd stable/fluentd-elasticsearch --namespace=$NAMESPACE --kubeconfig "/home/ubuntu/.kube/config"

# Kibana:
#kubectl port-forward --namespace logging $POD_NAME 5601:5601

# Elastic Search
#kubectl port-forward --namespace logging $POD_NAME 9200:9200