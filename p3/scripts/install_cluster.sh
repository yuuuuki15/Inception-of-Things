#!/bin/bash
# Installation script for part 3
# Setup k3d cluster and install Argo CD using Helm

# Exit immediately if a command exits with a non-zero status
set -e

HOST_PORT=8888
MANIFESTS_PATH=manifests

ARGOCD_HOSTNAME=argocd.local
ARGOCD_CONFIG_PATH=$MANIFESTS_PATH/argocd

################################# Kubernetes ###################################

create_k3d_cluster() {
    sudo k3d cluster create p3 -p "$HOST_PORT:80@loadbalancer"
    sudo kubectl create namespace argocd
    sudo kubectl create namespace dev
    echo "✅ Created k3d cluster."
}

################################### Argo CD ####################################

install_argocd(){
    # Add Argo CD Helm repository
    sudo helm repo add argo https://argoproj.github.io/argo-helm
    # Update information of available charts locally from chart repositories
    sudo helm repo update
    sudo helm upgrade --install argocd argo/argo-cd \
        --namespace argocd \
        --set server.ingress.enabled=true \
        --set configs.params."server\.insecure"=true \
        -f ./$ARGOCD_CONFIG_PATH/argocd_values.yaml

    # Update admin password
    sudo kubectl -n argocd patch secret argocd-secret \
        -p '{"stringData":  {
            "admin.password": "$2a$12$My3bM7RP8GTfgQyZr./ujuzxBSAul4q1vC1OG8lfPAyVsIx7aCq.6",
            "admin.passwordMtime": "'$(date +%FT%T%Z)'"
        }}'

    echo "✅ Installed Argo CD."
}

check_argocd_is_ready() {
    echo "⌛ Wait for Argo CD pods to be running ..."

    while true; do
        expected_pods_count=$(sudo kubectl get pods -n argocd --no-headers | wc -l)
        functional_pods=$(sudo kubectl get pods -n argocd | awk '{print $3}' | grep "Running" | wc -l)
        if [ $functional_pods = $expected_pods_count ]; then
            echo "✅ Argo CD server is ready."
            break
        fi
        echo "$functional_pods/$expected_pods_count pods are running ..."
        sleep 5
    done
}

create_argocd_ingress() {
    sudo kubectl apply -f ./$ARGOCD_CONFIG_PATH/argocd_ingress.yaml --namespace argocd
    # Add hostname to hosts
    echo "127.0.0.1 $ARGOCD_HOSTNAME" | sudo tee -a /etc/hosts

    echo "✅ Setup Ingress for Argo CD."
}

install_web_app(){
    echo "⌛ Create Argo CD 'development' project and 'playground' application."
    sudo kubectl apply -f ./$ARGOCD_CONFIG_PATH/argocd_projects.yaml
    sudo kubectl apply -f ./$ARGOCD_CONFIG_PATH/argocd_apps.yaml
    sudo kubectl apply -f ./$MANIFESTS_PATH/playground_ingress.yaml

    echo "✅ Setup application."
}

display_argocd_help() {
    echo "In order to access the server UI:

    1. Open the browser on http://$ARGOCD_HOSTNAME:$HOST_PORT
    2. Log in with 'admin' as username and ask the password to the evaluated students. :)\n"
}

################################################################################

create_k3d_cluster

############### Argo CD ###############
install_argocd
check_argocd_is_ready
create_argocd_ingress
install_web_app
display_argocd_help
