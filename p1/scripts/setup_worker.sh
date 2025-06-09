#!/bin/bash
# Set up Worker machine
SERVER_IP_ADDRESS="192.168.56.110"
K3S_SERVER_URL="https://${SERVER_IP_ADDRESS}:6443"
K3S_TOKEN_PATH="/vagrant/shared/node-token"

apt update && apt install -y curl vim
# Install k3s
curl -sfL https://get.k3s.io | K3S_URL=${K3S_SERVER_URL} K3S_TOKEN=$(cat ${K3S_TOKEN_PATH}) sh -

# Enable auto-completion for kubectl
echo 'source <(kubectl completion bash)' >>/home/vagrant/.bashrc
# Create an alias for kubectl
echo 'alias k=kubectl' >>/home/vagrant/.bashrc
# Extend shell completion to work with that alias
echo 'complete -o default -F __start_kubectl k' >>/home/vagrant/.bashrc
