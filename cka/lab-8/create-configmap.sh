#!/bin/bash

mkdir -p primary

echo c > primary/cyan
echo c > primary/argenta
echo c > primary/yellow
echo c > primary/black

echo "known as key" >> primary/black

echo "blue" > favorite

kubectl create configmap colors --from-literal text=black --from-file ./favorite --from-file ./primary/

rm -r primary
rm favorite

#black=c
#known as key
#
#argenta=c
#
#KUBERNETES_SERVICE_PORT_HTTPS=443
#cyan=c
#
#yellow=c
#
#KUBERNETES_SERVICE_PORT=443
#HOSTNAME=shell-demo
#PWD=/
#PKG_RELEASE=1~bookworm
#HOME=/root
#KUBERNETES_PORT_443_TCP=tcp://10.96.0.1:443
#text=black
#NJS_VERSION=0.8.3
#favorite=blue
#
#SHLVL=0
#KUBERNETES_PORT_443_TCP_PROTO=tcp
#KUBERNETES_PORT_443_TCP_ADDR=10.96.0.1
#KUBERNETES_SERVICE_HOST=10.96.0.1
#KUBERNETES_PORT=tcp://10.96.0.1:443
#KUBERNETES_PORT_443_TCP_PORT=443
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
#NGINX_VERSION=1.25.4
#_=/usr/bin/env