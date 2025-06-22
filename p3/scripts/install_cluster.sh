#!/bin/bash
# Install k3d cluster and Argo CD using Helm

# Exit immediately if a command exits with a non-zero status
set -e

create_k3d_cluster() {
    sudo k3d cluster create p3 -p "8080:80@loadbalancer"
    echo "✅ Created k3d cluster."
}

install_argocd(){
    sudo kubectl create namespace argocd

    # Add Argo CD Helm repository
    sudo helm repo add argo https://argoproj.github.io/argo-helm
    # Update information of available charts locally from chart repositories
    sudo helm repo update
    sudo helm upgrade --install argocd argo/argo-cd \
      --namespace argocd \
      --set server.ingress.enabled=true \
      --set configs.params."server\.insecure"=true

    echo "✅ Installed Argo CD."
}

check_argocd_is_ready() {
    echo "⌛ Wait for Argo CD pods to be running ..."

    while true; do
        number_of_pods=$(sudo kubectl get pods -n argocd | awk '{print $3}' | grep "Running" | wc -l)
        if [ $number_of_pods = "7" ]; then
            echo "✅ Argo CD server is ready."
            break
        fi
        echo "$number_of_pods/7 pods are running ..."
        sleep 5
    done
}

create_argocd_ingress() {
    sudo kubectl apply -f manifests/argocd-ingress.yaml --namespace argocd
    # Add hostname to hosts
    echo "127.0.0.1 argocd.local" | sudo tee -a /etc/hosts

    echo "✅ Setup Ingress for Argo CD."
}

display_help() {
    argocd_password=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

    echo "In order to access the server UI:

    1. Open the browser on http://argocd.local:8080

    2. Log in with 'admin:$argocd_password'"
}

create_k3d_cluster
install_argocd
# Wait for Argo CD server to be ready
check_argocd_is_ready
# Create Ingress to access Argo CD UI
create_argocd_ingress
display_help
