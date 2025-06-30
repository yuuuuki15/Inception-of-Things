#!/bin/bash
# Install k3d cluster and Argo CD using Helm

# Exit immediately if a command exits with a non-zero status
set -e

ARGOCD_HOSTNAME=argocd.local
PORT=8080
PLAYGROUND_PORT=8888

GITLAB_HOSTNAME=gitlab.local
CERT_DIR=./certs
SECRET_NAME=gitlab-tls

create_k3d_cluster() {
    sudo k3d cluster create p3 \
        -p "$PORT:80@loadbalancer" \
        -p "8888:$PLAYGROUND_PORT@loadbalancer"
    sudo kubectl create namespace argocd
    sudo kubectl create namespace dev
    sudo kubectl create namespace gitlab
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
    sudo kubectl apply -f ./manifests/argocd_ingress.yaml --namespace argocd
    # Add hostname to hosts
    echo "127.0.0.1 $ARGOCD_HOSTNAME" | sudo tee -a /etc/hosts

    echo "✅ Setup Ingress for Argo CD."
}

install_web_app(){
    echo "⌛ Create Argo CD 'development' project and 'playground' application."
    sudo kubectl apply -f ./manifests/project_development.yaml
    sudo kubectl apply -f ./manifests/app_playground.yaml
}

display_help() {
    argocd_password=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

    echo -e "In order to access the server UI:

    1. Open the browser on http://$ARGOCD_HOSTNAME:$PORT

    2. Log in with 'admin:$argocd_password'\n\n"
}

install_argocd_cli(){
    argocd_version=v3.0.6
    echo "⌛ Downloading Argo CD command-line tool ..."
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$argocd_version/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64

    echo "✅ Installed Argo CD CLI."
}

connect_to_argocd() {
    echo "⌛ Connect to Argo CD server with CLI ..."
    argocd_password=$(sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

    argocd login --plaintext --grpc-web --username admin --password $argocd_password $ARGOCD_HOSTNAME:$PORT
}

# doc: https://docs.gitlab.com/charts/installation/deployment/
# doc: https://docs.gitlab.com/charts/charts/globals/#configure-host-settings
install_gitlab() {
    helm repo add gitlab https://charts.gitlab.io/
    helm repo update
    helm upgrade --install gitlab gitlab/gitlab \
    --namespace gitlab \
    --timeout 600s \
    --set global.hosts.domain=$GITLAB_HOSTNAME \
    --set global.hosts.externalIP=127.0.0.1 \
    --set certmanager-issuer.email=me@$GITLAB_HOSTNAME \
    --set gitlab-runner.install=false \
    --set global.edition=ce \
    --set postgresql.resources.requests.cpu=200m \
    --set postgresql.resources.requests.memory=256Mi \
    --set redis.resources.requests.cpu=100m \
    --set redis.resources.requests.memory=128Mi \
    --set global.minio.resources.requests.memory=128Mi \
    --set global.webservice.minReplicas=1 \
    --set global.webservice.maxReplicas=1

    echo "✅ Installed GitLab."
}

check_gitlab_is_ready() {
    echo "⌛ Wait for GitLab pods to be running ..."

    while true; do
        number_of_pods=$(sudo kubectl get pods -n gitlab | awk '{print $3}' | grep "Running" | wc -l)
        if [ $number_of_pods = "20" ]; then
            echo "✅ GitLab server is ready."
            break
        fi
        echo "$number_of_pods/20 pods are running ..."
        sleep 5
    done
}

gitlab_certificates() {
    echo "⌛ Generate self-signed certificates for GitLab ..."
    sudo mkdir -p $CERT_DIR
    rm -rf $CERT_DIR/gitlab.key $CERT_DIR/gitlab.crt
    sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
        -keyout $CERT_DIR/gitlab.key \
        -out $CERT_DIR/gitlab.crt \
        -subj "/O=LocalGitLab/CN=$GITLAB_HOSTNAME"
    echo "✅ Generated self-signed certificates for GitLab."

    # === DELETE EXISTING SECRET (IF ANY) ===
    sudo kubectl delete secret "$SECRET_NAME" -n gitlab --ignore-not-found
    # === CREATE SECRET WITH CERTIFICATES ===
    sudo kubectl create secret tls "$SECRET_NAME" \
        --cert=$CERT_DIR/gitlab.crt \
        --key=$CERT_DIR/gitlab.key \
        -n gitlab

    echo "✅ TLS certificate and key created for GitLab."
}

create_gitlab_ingress() {
    sudo kubectl apply -f ./manifests/gitlab_ingress.yaml --namespace gitlab
    # Add hostname to hosts
    echo "127.0.0.1 $GITLAB_HOSTNAME" | sudo tee -a /etc/hosts

    echo "✅ Setup Ingress for GitLab."
}

display_gitlab_help() {
    gitlab_password=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)

    echo -e "In order to access the GitLab server UI:

    1. Open the browser on http://$GITLAB_HOSTNAME:$PORT

    2. Log in with 'root:$gitlab_password'\n\n"
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

install_gitlab

check_gitlab_is_ready

gitlab_certificates

create_gitlab_ingress
# now ingress doesn't work, so we use port-forwarding
# sudo kubectl port-forward svc/gitlab-webservice-default -n gitlab 8083:8080
# Although we can access GitLab via port-forwarding, we have this error while loging in "422: The change you requested was rejected"

display_gitlab_help
