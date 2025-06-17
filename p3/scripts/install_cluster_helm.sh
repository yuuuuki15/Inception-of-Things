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
# Update information of available charts locally from chart repositories
sudo helm repo update
# Install Argo CD
sudo helm install argocd argo/argo-cd --namespace argocd

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

# get password
password=$(sudo kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)

# login
echo "password: $password"

# Port forward Argo CD server to localhost
# we're using port 8081 to avoid conflict with the default port 8080(ssh)
sudo kubectl port-forward service/argocd-server -n argocd 8081:443

echo "Argo CD is now accessible at https://localhost:8081"
echo "You can log in with the username 'admin' and the password \"$password\"."
