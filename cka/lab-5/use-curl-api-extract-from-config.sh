#!/bin/bash

CLIENT_CERT=$(grep client-cert ~/.kube/config | cut -d" " -f 6)
CLIENT_CERT_FILE=""
if test -f "$CLIENT_CERT"; then
  # the value is the file location
  CLIENT_CERT_FILE=$CLIENT_CERT
else
  # the content is the key itself
  CLIENT_CERT_FILE="/tmp/kube-client.pem"
  echo "$CLIENT_CERT" | base64 -d - > "$CLIENT_CERT_FILE"
fi


CLIENT_KEY=$(grep client-key ~/.kube/config | cut -d" " -f 6)
CLIENT_KEY_FILE=""
if test -f "$CLIENT_KEY"; then
  # the value is the file location
  CLIENT_KEY_FILE=$CLIENT_KEY
else
  # the content is the key itself
  CLIENT_KEY_FILE="/tmp/kube-client.key"
  CLIENT_KEY=$(grep client-key-data ~/.kube/config | cut -d " " -f 6)
  echo "$CLIENT_KEY" | base64 -d - > "$CLIENT_KEY_FILE"
fi

CA_CERT=$(grep ertificate-authority ~/.kube/config | cut -d" " -f 6)
CAR_CERT_FILE=""
if test -f "$CA_CERT"; then
  # the value is the file location
  CAR_CERT_FILE=$CA_CERT
else
  # the content is the key itself
  CAR_CERT_FILE="/tmp/kube-ca.pem"
  CA_CERT=$(grep certificate-authority-data ~/.kube/config | cut -d " " -f 6)
  echo "$CA_CERT" | base64 -d - > "$CAR_CERT_FILE"
fi


SERVER=$(kubectl config view | grep server | cut -d " " -f 6)
URL="${SERVER}/api$1"

curl --cert "$CLIENT_CERT_FILE" --key "$CLIENT_KEY_FILE" --cacert "$CAR_CERT_FILE" "$URL"
