#!/bin/bash
# Install cluster and Argo CD using Helm

# Exit immediately if a command exits with a non-zero status
set -e

# Create cluster
sudo k3d cluster create p3 --agents 2 -p "8080:80@loadbalancer"
# Create namespaces
sudo kubectl create namespace argocd
sudo kubectl create namespace dev

# Add Argo CD Helm repository
sudo helm repo add argo https://argoproj.github.io/argo-helm
# Add Nginx Helm repository
sudo helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Update information of available charts locally from chart repositories
sudo helm repo update

# Install Argo CD
sudo helm install argocd argo/argo-cd --namespace argocd
# Install Nginx
sudo helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace

# Wait for argocd server to be ready
while true; do
    number_of_pods=$(sudo kubectl get pods -n argocd | awk '{print $3}' | grep "Running" | wc -l)
    if [ $number_of_pods = "7" ]; then
        echo "Argocd server is ready."
        break
    fi
    echo "($number_of_pods/7) Waiting for Argo CD server to be ready..."
    sleep 5
done

# Create Ingress
sudo kubectl apply -f manifests/ingress.yaml --namespace argocd
