#!/bin/bash

JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]} {@.type}={@.status};{end}{end}'

while [[ -z $(kubectl get nodes -o jsonpath="$JSONPATH" | grep "Ready=True" ) ]]; do
  echo "Node not ready, waiting 30s"
  sleep 30
done

echo "CP node ready"

JOIN_COMMAND=$(sh /home/ubuntu/join-command-helper.sh)

chmod 0700 /home/ubuntu/node.key
ssh -o StrictHostKeyChecking=no -i /home/ubuntu/node.key ubuntu@worker.sfeir.local "${JOIN_COMMAND}"