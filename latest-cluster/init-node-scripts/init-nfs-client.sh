#!/bin/bash

sudo apt-get install -y nfs-common

# Tests
showmount -e cp.sfeir.local
sudo mount cp.sfeir.local:/opt/sfw /mnt
ls -l /mnt