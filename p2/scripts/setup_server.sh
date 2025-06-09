#!/bin/bash
# Set up Server machine
K3S_TOKEN_PATH="/vagrant/shared/node-token"

apt update && apt install -y curl vim

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
# Share the token for the workers
cp /var/lib/rancher/k3s/server/node-token ${K3S_TOKEN_PATH}

# Enable auto-completion for kubectl
echo 'source <(kubectl completion bash)' >>/home/vagrant/.bashrc
# Create an alias for kubectl
echo 'alias k=kubectl' >>/home/vagrant/.bashrc
# Extend shell completion to work with that alias
echo 'complete -o default -F __start_kubectl k' >>/home/vagrant/.bashrc
