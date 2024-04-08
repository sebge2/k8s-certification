#!/bin/bash

# Arguments:
# user name
# password
# namespace

sudo useradd -s /bin/bash "$1"
echo "$1:$2" | sudo chpasswd

openssl genrsa -out "$1.key" 2048
openssl req -new -key "$1.key" -out "$1.csr" -subj "/CN=$1/O=$3"
sudo openssl x509 -req -in "$1.csr" -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out "$1.crt" -days 45


echo "kubectl config set-credentials \"$1\" --client-certificate=\"$1.crt\" --client-key=\"$1.key\""
echo "kubectl config set-context $1-context --cluster=kubernetes --namespace=$3 --user=$1"
