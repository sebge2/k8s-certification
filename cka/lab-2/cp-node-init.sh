#!/bin/bash


# Install Kube Tools https://v1-28.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
# 1. Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo apt-get install -y apt-transport-https ca-certificates software-properties-common lsb-release curl gpg

# 2. Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 3. Add the appropriate Kubernetes apt repository. Please note that this repository have packages only for Kubernetes 1.28; for other Kubernetes minor versions, you need to change the Kubernetes minor version in the URL to match your desired minor version (you should also check that you are reading the documentation for the version of Kubernetes that you plan to install).
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# 4.  Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
sudo apt-get install -y kubelet=1.28.7-1.1 kubeadm=1.28.7-1.1 kubectl=1.28.7-1.1
sudo apt-mark hold kubelet kubeadm kubectl


# Install Docker https://docs.docker.com/engine/install/ubuntu/
# 1. Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 2. Add the repository to Apt sources:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# 3. Install Docker
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# 4. Configure containerd
sudo containerd config default | tee /etc/containerd/config.toml
sudo sed -e 's/SystemdCgroup = false/SystemdCgroup = true/g' -i /etc/containerd/config.toml
sudo systemctl restart containerd


# Configure System
swapoff -a
sudo modprobe overlay
sudo modprobe br_netfilter

cat << EOF | sudo tee /etc/sysctl.d/kubernetes.conf
    net.bridge.bridge-nf-call-ip6tables = 1
    net.bridge.bridge-nf-call-iptables = 1
    net.ipv4.ip_forward = 1
EOF

echo "$(hostname -i) k8scp" | sudo tee -a /etc/hosts


# Install Control Pane
cat << EOF | sudo tee /home/ubuntu/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
kubernetesVersion: 1.28.7
controlPlaneEndpoint: "k8scp:6443"
networking:
  podSubnet: 10.0.101.0/24
EOF


# Start Control Pane
sudo kubeadm init --config=/home/ubuntu/kubeadm-config.yaml --upload-certs | sudo tee /home/ubuntu/kubeadm-init.out


# Setup Kube Config
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config


# Install Helm https://helm.sh/docs/intro/install/
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm


# Install Cilium
helm repo add cilium https://helm.cilium.io/
helm repo update
helm template cilium cilium/cilium --version 1.14.1 --namespace kube-system > /home/ubuntu/cilium.yaml
kubectl apply -f /home/ubuntu/cilium.yaml


# Completion
sudo apt-get install bash-completion -y
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> /home/ubuntu/.bashrc