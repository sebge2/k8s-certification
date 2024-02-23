#!/bin/bash

TODAY=$(date +%m-%d-%y)
BACKUP_DIR=~/backup/"$TODAY"

rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

kubectl -n kube-system exec -it etcd-ip-10-0-101-55 -- sh -c "ETCDCTL_API=3 ETCDCTL_CACERT=/etc/kubernetes/pki/etcd/ca.crt ETCDCTL_CERT=/etc/kubernetes/pki/etcd/server.crt ETCDCTL_KEY=/etc/kubernetes/pki/etcd/server.key etcdctl --endpoints=https://127.0.0.1:2379 snapshot save /var/lib/etcd/snapshot.db"
sudo cp /var/lib/etcd/snapshot.db "$BACKUP_DIR"
cp ~/kubeadm-config.yaml "$BACKUP_DIR"
sudo cp -r /etc/kubernetes/pki/etcd "$BACKUP_DIR"


