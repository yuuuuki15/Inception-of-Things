#!/bin/bash

# check installation

check_installation() {
    local missing=()
    for cmd in "$@"; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -ne 0 ]; then
        echo "Missing commands: ${missing[*]}"
        return 1
    else
        echo "All commands are installed"
        return 0
    fi
}

# install docker
# ------------------------------------------
check_docker_installation() {
    # doc: https://github.com/docker/docker-install/blob/master/verify-docker-install

    # Verify that we can at least get version output
    if ! docker --version; then
        echo "ERROR: Did Docker get installed?"
        return 1
    fi

    # Attempt to run a container if not in a container
    if [ ! -f /.dockerenv  ]; then
        if ! docker run --rm hello-world; then
            echo "ERROR: Could not get docker to run the hello world container"
            return 2
        fi
    fi

    return 0
}

# doc: https://docs.docker.com/engine/install/debian/
install_docker() {
    # Add Docker's official GPG key:
    sudo apt-get -y update
    sudo apt-get -y install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get -y update

    # install latest docker engine
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

if ! check_docker_installation; then
    echo "Docker is not installed or not working correctly. Installing Docker..."
    install_docker
    if ! check_docker_installation; then
        echo "Docker installation failed. Exiting."
        exit 1
    fi
else
    echo "Docker is already installed and working correctly."
fi

# ------------------------------------------
# install kubectl
# doc: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

install_kubectl() {
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
}
if ! check_installation kubectl; then
    echo "kubectl is not installed. Installing kubectl..."
    install_kubectl
    if ! check_installation kubectl; then
        echo "kubectl installation failed. Exiting."
        exit 1
    fi
else
    echo "kubectl is already installed."
fi

# ------------------------------------------

# install k3d
# doc: https://k3d.io/stable/#installation
install_k3d () {
    curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}
if ! check_installation k3d; then
    echo "k3d is not installed. Installing k3d..."
    install_k3d
    if ! check_installation k3d; then
        echo "k3d installation failed. Exiting."
        exit 1
    fi
else
    echo "k3d is already installed."
fi
# ------------------------------------------

# alias kubectl to k
if ! command -v k &> /dev/null; then
    echo "Creating alias 'k' for kubectl..."
    echo 'alias k="kubectl"' | sudo tee /etc/profile.d/k3s-aliases.sh
    sudo chmod +x /etc/profile.d/k3s-aliases.sh
    source /etc/profile.d/k3s-aliases.sh
else
    echo "Alias 'k' for kubectl already exists."
fi

# ------------------------------------------
# install helm
# doc: https://helm.sh/docs/intro/install/
install_helm() {
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm ./get_helm.sh

    echo "✅ Helm"
}

if ! check_installation helm; then
    echo "Helm is not installed. Installing Helm..."
    install_helm
    if ! check_installation helm; then
        echo "Helm installation failed. Exiting."
        exit 1
    fi
else
    echo "Helm is already installed."
fi
