#!/bin/bash

NAMESPACE="kube-logging"

kubectl create ns $NAMESPACE --kubeconfig /home/ubuntu/.kube/config

helm repo add elastic https://helm.elastic.co
helm repo add fluent https://fluent.github.io/helm-charts
helm repo update


# https://artifacthub.io/packages/helm/elastic/elasticsearch?modal=values
helm install elasticsearch elastic/elasticsearch --namespace=$NAMESPACE --kubeconfig "/home/ubuntu/.kube/config"  -f -<<EOF
service:
  nodePort: 31501
  type: NodePort
replicas: 1
persistence:
  enabled: false
EOF

ELASTIC_TOKEN=$(kubectl get secrets --namespace=$NAMESPACE elasticsearch-master-credentials -ojsonpath='{.data.password}' --kubeconfig /home/ubuntu/.kube/config | base64 -d)
echo "Elastic Password for 'elastic' user:"
echo "$ELASTIC_TOKEN"

# Debug:
#curl -XPOST https://worker-0.sfeir.local:31501/test-index/_doc -H "Content-Type: application/json" -d '{"name":"John Smith", "age":"38"}' -u "elastic:$ELASTIC_TOKEN" -k


# https://artifacthub.io/packages/helm/elastic/kibana?modal=values
helm install kibana elastic/kibana --namespace=$NAMESPACE --kubeconfig "/home/ubuntu/.kube/config" -f -<<EOF
service:
  nodePort: 31502
  type: NodePort
EOF

USER_PWD=$(kubectl get secrets --namespace=$NAMESPACE elasticsearch-master-credentials -ojsonpath='{.data.password}' --kubeconfig /home/ubuntu/.kube/config | base64 -d)
echo "Kibana Password for 'elastic' user:"
echo "$USER_PWD"


# https://github.com/fluent/helm-charts/blob/main/charts/fluent-bit/values.yaml
# https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes
helm install fluentd fluent/fluent-bit --namespace=$NAMESPACE --kubeconfig "/home/ubuntu/.kube/config" -f -<<EOF
config:
  outputs: |
    [OUTPUT]
        Name es
        Match kube.*
        Host elasticsearch-master
        Logstash_Format Off
        Retry_Limit False
        Suppress_Type_Name On
        Write_Operation upsert
        Generate_ID true
        Replace_Dots true
        Trace_Error On
        HTTP_User elastic
        HTTP_Passwd $ELASTIC_TOKEN
        tls On
        tls.verify Off

    [OUTPUT]
        Name es
        Match host.*
        Host elasticsearch-master
        Logstash_Format Off
        Logstash_Prefix node
        Retry_Limit False
        Suppress_Type_Name On
        Write_Operation upsert
        Generate_ID true
        Replace_Dots true
        Trace_Error On
        HTTP_User elastic
        HTTP_Passwd $ELASTIC_TOKEN
        tls On
        tls.verify Off
EOF

# Debug with:
# kubectl run tmp-shell --rm -i --tty --image nicolaka/netshoot -n kube-logging -- bash
# curl -v https://elasticsearch-master:9200