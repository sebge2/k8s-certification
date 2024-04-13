#!/bin/bash

bash

JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]} {@.type}={@.status};{end}{end}'

while [ -z "$(sudo -u ubuntu kubectl get nodes -o jsonpath="$JSONPATH" | grep "Ready=True" )" ]; do
  echo "Node not ready, waiting 30s"
  sleep 30
done

echo "CP node ready, let's provision $1 worker nodes"

JOIN_COMMAND=$(sh /home/ubuntu/init-scripts/join-command-helper.sh)

chmod 0700 /home/ubuntu/node.key

START=0
END=$(($1-1))
for i in $(seq $START $END)
do
  ssh -o StrictHostKeyChecking=no -i /home/ubuntu/node.key "ubuntu@worker-${i}.sfeir.local" "${JOIN_COMMAND}"
done