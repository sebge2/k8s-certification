#!/bin/bash

# Completion
sudo apt-get install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> /home/ubuntu/.bashrc