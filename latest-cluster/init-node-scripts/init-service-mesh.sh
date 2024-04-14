#!/bin/bash

export HOME=/home/ubuntu
curl -sL run.linkerd.io/install | sh
export PATH=$PATH:$HOME/.linkerd2/bin
echo "export PATH=$PATH:$HOME/.linkerd2/bin" >> $HOME/.bashrc

echo "Pre check"
linkerd check --pre

linkerd install --crds | kubectl apply --kubeconfig /home/ubuntu/.kube/config -f -
linkerd install | kubectl apply --kubeconfig /home/ubuntu/.kube/config -f -

echo "Check"
linkerd check

echo "viz Check"
linkerd viz install | kubectl apply --kubeconfig /home/ubuntu/.kube/config -f -
linkerd viz check

kubectl patch deployment web --kubeconfig /home/ubuntu/.kube/config --namespace linkerd-viz --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": ["-linkerd-metrics-api-addr=metrics-api.linkerd-viz.svc.cluster.local:8085","-cluster-domain=cluster.local","-controller-namespace=linkerd","-log-level=info","-log-format=plain","-enforced-host=","-enable-pprof=false"]}]'
kubectl patch service web --kubeconfig /home/ubuntu/.kube/config --namespace linkerd-viz --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}, {"op": "replace", "path": "/spec/ports/0/nodePort", "value": 31500}]'

echo "Launch dashboard"
nohup linkerd viz dashboard &
