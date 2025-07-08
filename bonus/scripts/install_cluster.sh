#!/bin/bash
# Installation script for bonus part
# Setup k3d cluster, and install Argo CD and GitLab using Helm

# Exit immediately if a command exits with a non-zero status
set -e

HOST_PORT=8888
MANIFESTS_PATH=manifests
IOT_HOSTNAME=iot.local

ARGOCD_HOSTNAME=argocd.$IOT_HOSTNAME
ARGOCD_CONFIG_PATH=$MANIFESTS_PATH/argocd

GITLAB_HOSTNAME=gitlab.$IOT_HOSTNAME

################################# Kubernetes ###################################

create_k3d_cluster() {
    sudo k3d cluster create bonus -p "$HOST_PORT:80@loadbalancer"
    sudo kubectl create namespace argocd
    sudo kubectl create namespace dev
    sudo kubectl create namespace gitlab
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
        functional_pods=$(sudo kubectl get pods -n argocd | awk '{print $3}' | grep "Running\|Completed" | wc -l)
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
    2. Log in with 'admin' as username and ask the password to the students. :)\n"
}

#################################### GitLab ####################################

# doc: https://docs.gitlab.com/charts/installation/deployment/
# doc: https://docs.gitlab.com/charts/charts/globals/#configure-host-settings
install_gitlab() {
    helm repo add gitlab https://charts.gitlab.io/
    helm repo update
    helm upgrade --install gitlab gitlab/gitlab \
        --timeout 600s \
        --namespace gitlab \
        --set certmanager.install=false \
        --set gitlab-runner.install=false \
        --set gitlab.gitlab-shell.service.type=ClusterIP \
        --set gitlab.gitlab-shell.service.port=2222 \
        --set gitlab.sidekiq.concurrency=10 \
        --set gitlab.sidekiq.registry.enabled=false \
        --set gitlab.webservice.registry.enabled=false \
        --set global.appConfig.dependencyProxy.enabled=false \
        --set global.edition=ce \
        --set global.hosts.gitlab.name=$GITLAB_HOSTNAME \
        --set global.hosts.gitlab.https=false \
        --set global.hosts.ssh=ssh.$GITLAB_HOSTNAME \
        --set global.hosts.https=false \
        --set global.ingress.class=nginx \
        --set global.ingress.configureCertmanager=false \
        --set global.ingress.enabled=true \
        --set global.ingress.tls.enabled=false \
        --set global.shell.port=2222 \
        --set nginx-ingress.enabled=false \
        --set prometheus.install=false \
        --set registry.enabled=false

    echo "✅ Installed GitLab."
}

check_gitlab_is_ready() {
    echo "⌛ Wait for GitLab pods to be running ..."

    while true; do
        expected_pods_count=$(sudo kubectl get pods -n gitlab --no-headers | wc -l)
        functional_pods=$(sudo kubectl get pods -n gitlab | awk '{print $3}' | grep "Running\|Completed" | wc -l)

        if [ $functional_pods = $expected_pods_count ]; then
            break
        fi
        echo "$functional_pods/$expected_pods_count pods are running ..."
        sleep 5
    done

    while true; do
        response=$(curl --silent http://$GITLAB_HOSTNAME:$HOST_PORT)
        pending_result='{"status":"ok", "message": "v1"}'

        if [ "$response" != "$pending_result" ]; then
            break
        fi
        echo "⌛ Wait for GitLab to be ready ..."
        sleep 5
    done

    echo "✅ GitLab is ready."
}

create_gitlab_ingress() {
    sudo kubectl apply -f ./$MANIFESTS_PATH/gitlab_ingress.yaml --namespace gitlab
    # Add hostname to hosts
    echo "127.0.0.1 $GITLAB_HOSTNAME" | sudo tee -a /etc/hosts

    echo """Host ssh.gitlab.iot.local
User git
Port 8888

    """ >> ~/.ssh/config

    echo "✅ Setup Ingress for GitLab."
}

display_gitlab_help() {
    gitlab_password=$(sudo kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -o jsonpath="{.data.password}" | base64 -d)

    echo -e "In order to access the GitLab server UI:

    1. Open the browser on http://$GITLAB_HOSTNAME:$HOST_PORT
    2. Log in with 'root:$gitlab_password'\n"
}

################################################################################

create_k3d_cluster

############### Argo CD ###############
install_argocd
check_argocd_is_ready
create_argocd_ingress
install_web_app
display_argocd_help

############## GitLab ###############
install_gitlab
check_gitlab_is_ready
create_gitlab_ingress
display_gitlab_help
