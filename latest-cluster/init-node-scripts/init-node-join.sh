#!/bin/bash

NUMBER_CP_NODES=$1
NUMBER_WORKER_NODES=$2

wait_node () {
  NODE_NAME=$1
  JSONPATH='{@.metadata.name}:{range @.status.conditions[*]} {@.type}={@.status};{end}'

  while [ -z "$(sudo -u ubuntu kubectl get nodes "${NODE_NAME}" --kubeconfig /home/ubuntu/.kube/config -o jsonpath="$JSONPATH" | grep "Ready=True" )" ]; do
    echo "Node ${NODE_NAME} not ready, waiting 10s"
    sleep 10
  done

  echo "Node ${NODE_NAME} ready."
}

wait_node "cp-0"

UPLOAD_CERT=$(sudo kubeadm init phase upload-certs --upload-certs)
echo "$UPLOAD_CERT"
CERTIFICATE_KEY=$(echo "$UPLOAD_CERT" | sed -n 's/.*--certificate-key //p')

if [ "$NUMBER_CP_NODES" -gt 1 ]; then
  echo "Provisioning more control plane nodes $NUMBER_CP_NODES."

  END=$(($NUMBER_CP_NODES-1))
  for i in $(seq 1 "$END")
  do
    NODE="cp-$i"
    JOIN_COMMAND=$(sh /home/ubuntu/init-node-scripts/join-cp-command-helper.sh "$i" "$CERTIFICATE_KEY")

    echo "Initializing node $NODE."

    ssh -o StrictHostKeyChecking=no -i /home/ubuntu/node.key "ubuntu@${NODE}.sfeir.local" "${JOIN_COMMAND}"

    wait_node "$NODE"
  done
fi

if [ "$NUMBER_WORKER_NODES" -gt 1 ]; then
  END=$(($NUMBER_WORKER_NODES-1))
  for i in $(seq 0 $END)
  do
    NODE="worker-$i"
    JOIN_COMMAND=$(sh /home/ubuntu/init-node-scripts/join-worker-command-helper.sh "$i")

    echo "Initializing node $NODE."

    ssh -o StrictHostKeyChecking=no -i /home/ubuntu/node.key "ubuntu@${NODE}.sfeir.local" "${JOIN_COMMAND}"
  done
fi