#!/bin/bash
# Install k3d cluster and Argo CD using Helm

# Exit immediately if a command exits with a non-zero status
set -e

ARGOCD_HOSTNAME=argocd.local
ARGOCD_CONFIG_PATH=manifests/argocd
PORT=8888

create_k3d_cluster() {
    sudo k3d cluster create p3 \
        -p "$PORT:80@loadbalancer"
    sudo kubectl create namespace argocd
    sudo kubectl create namespace dev
    echo "✅ Created k3d cluster."
}

install_argocd(){
    # Add Argo CD Helm repository
    sudo helm repo add argo https://argoproj.github.io/argo-helm
    # Update information of available charts locally from chart repositories
    sudo helm repo update
    sudo helm upgrade --install argocd argo/argo-cd \
        --namespace argocd \
        --set server.ingress.enabled=true \
        --set configs.params."server\.insecure"=true \
        -f ./$ARGOCD_CONFIG_PATH/argocd-values.yaml

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
    sudo kubectl apply -f ./$ARGOCD_CONFIG_PATH/argocd_ingress.yaml --namespace argocd
    # Add hostname to hosts
    echo "127.0.0.1 $ARGOCD_HOSTNAME" | sudo tee -a /etc/hosts

    echo "✅ Setup Ingress for Argo CD."
}

install_web_app(){
    echo "⌛ Create Argo CD 'development' project and 'playground' application."
    sudo kubectl apply -f ./$ARGOCD_CONFIG_PATH/argocd_projects.yaml
    sudo kubectl apply -f ./$ARGOCD_CONFIG_PATH/argocd_apps.yaml
    sudo kubectl apply -f ./manifests/playground_ingress.yaml

    echo "✅ Setup application."
}

display_help() {
    echo "In order to access the server UI:

    1. Open the browser on http://$ARGOCD_HOSTNAME:$PORT
    2. Log in with 'admin' as username and ask the password to the students. :)\n"
}

install_argocd_cli(){
    argocd_version=v3.0.6
    echo "⌛ Downloading Argo CD command-line tool ..."
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$argocd_version/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64

    echo "✅ Installed Argo CD CLI."
}

create_k3d_cluster
install_argocd
# Wait for Argo CD server to be ready
check_argocd_is_ready
# Create Ingress to access Argo CD UI
create_argocd_ingress
# Install playground web application
install_web_app
display_help
