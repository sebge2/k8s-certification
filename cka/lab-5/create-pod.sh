#!/bin/bash

JSON_CONTENT=$(cat << EndOfText
{
  "kind": "Pod",
  "apiVersion": "v1",
  "metadata": {
    "name": "curlpod",
    "namespace": "default",
    "labels": {
      "name": "examplepod"
    }
  },
  "spec": {
    "containers": [
      {
        "name": "nginx",
        "image": "nginx",
        "ports": [
          {
            "containerPort": 80
          }
        ]
      }
    ]
  }
}
EndOfText
)

curl --cert ~/.minikube/profiles/minikube/client.crt --key ~/.minikube/profiles/minikube/client.key --cacert ~/.minikube/ca.crt https://127.0.0.1:57894/api/v1/namespaces/default/pods -XPOST -H'Content-Type: application/json' -d "$JSON_CONTENT"