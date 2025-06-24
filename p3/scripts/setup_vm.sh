#!/bin/bash
# Set up Virtual Machine for assignement part 3

# Exit immediately if a command exits with a non-zero status
set -e

check_success() {
    "$@"  # Execute parameter (here, the function whose exit status to check)
    local ret_val=$?

    if [ $ret_val -ne 0 ]; then
        echo "❌ Error: $*" >&2
        exit $ret_val
    fi
}

install_utils() {
    sudo apt update
    sudo apt install curl git vim

    echo "✅ Installed dependencies."
}

install_docker() {
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
        $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    # Install Docker packages
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    # Add the user to the Docker group
    sudo usermod -a -G docker $USER

    echo "✅ Installed and configured Docker."
}

install_kubectl() {
    curl -LO https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x ./kubectl
    sudo mv ./kubectl /usr/local/bin/kubectl

    # Enable autocompletion
    echo 'source <(kubectl completion bash)' >>~/.bashrc
    echo 'alias k=kubectl' >>~/.bashrc
    echo 'complete -o default -F __start_kubectl k' >>~/.bashrc

    echo "✅ Installed and configured kubectl."
}

install_k3d() {
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

    echo "✅ Installed k3d."
}

install_helm() {
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm ./get_helm.sh

    echo "✅ Installed Helm."
}

check_success install_utils
check_success install_docker
check_success install_kubectl
check_success install_k3d
check_success install_helm
