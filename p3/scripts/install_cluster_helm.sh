#!/bin/bash
# Install cluster and Argo CD using Helm

# Exit immediately if a command exits with a non-zero status
set -e

# Create cluster
sudo k3d cluster create p3 --agents 2
# Create namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

# Add Argo CD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
# Update information of available charts locally from chart repositories
helm repo update
# Install Argo CD
helm install argocd argo/argo-cd --namespace argocd
