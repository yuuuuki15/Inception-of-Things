#!/bin/bash
# Install cluster and Argo CD using Helm

# Exit immediately if a command exits with a non-zero status
set -e

# Add Argo CD Helm repository
sudo helm repo add argo https://argoproj.github.io/argo-helm
# Update information of available charts locally from chart repositories
sudo helm repo update
# Install Argo CD
sudo helm install argocd argo/argo-cd --namespace argocd

# Wait for argocd server to be ready
sudo kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# Create Ingress
sudo kubectl apply -f configs/ingress.yaml --namespace argocd

# get password
password=$(sudo kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)

# login
echo "Argo CD is now accessible at https://localhost:8081"
echo "You can log in with the username 'admin' and the password \"$password\"."

# Port forward Argo CD server to localhost
# we're using port 8081 to avoid conflict with the default port 8080(loadbalancer)
sudo kubectl port-forward service/argocd-server -n argocd 8081:443
