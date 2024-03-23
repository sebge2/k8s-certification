#!/bin/bash

rm -r .terraform &> /dev/null
rm terraform.tfstate &> /dev/null

mkdir -p ~/.aws/k8-certification
ssh-keygen -t rsa -b 4096 -C "k8s-certification" -f  ~/.aws/k8-certification/node -N ""

terraform init
