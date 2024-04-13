#!/bin/bash

sudo apt-get install -y nfs-kernel-server
sudo mkdir /opt/sfw
sudo chmod 1777 /opt/sfw

echo "software" | sudo tee /opt/sfw/hello.txt

echo "/opt/sfw/ *(rw,sync,no_root_squash,subtree_check)" | sudo tee /etc/exports
sudo exportfs -ra