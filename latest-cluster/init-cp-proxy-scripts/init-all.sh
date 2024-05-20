#!/bin/bash

mkdir -p /home/ubuntu/logs
mkdir -p /home/ubuntu/init-cp-proxy-scripts

sleep 60

mv /home/ubuntu/*.sh /home/ubuntu/init-cp-proxy-scripts/

sh -x /home/ubuntu/init-cp-proxy-scripts/init-proxy.sh "${numberCpNodes}">> /home/ubuntu/logs/init-proxy.log 2>&1