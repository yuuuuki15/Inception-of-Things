#!/bin/bash
# Install cluster and Argo CD

# Exit immediately if a command exits with a non-zero status
set -e

# Create cluster
sudo k3d cluster create p3 --agents 2
# Create namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

# Install Argo CD
sudo kubectl apply --namespace argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# Create Ingress
sudo kubectl apply --namespace argocd -f manifests/ingress.yaml
# Update hosts
echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts
