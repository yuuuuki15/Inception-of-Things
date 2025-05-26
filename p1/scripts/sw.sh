#!/bin/bash
echo "[INFO]  setting up k3s agent"
sudo apt update -y
sudo apt install -y curl

# check token
TIMEOUT=10
while [ ! -f /vagrant/shared/node-token ] && [ $TIMEOUT -gt 0 ]; do
    echo "Waiting for node-token to be available..."
    sleep 1
    TIMEOUT=$((TIMEOUT - 1))
done

export K3S_TOKEN=$(cat /vagrant/shared/node-token)
export K3S_URL="https://192.168.56.110:6443"
export INSTALL_K3S_EXEC="--flannel-iface=eth1"
# agent is assumed because of K3S_URL
echo "[INFO]  installing k3s agent"
curl -sfL https://get.k3s.io | sh -s -
echo "[INFO]  k3s agent installed"

echo 'alias k="kubectl"' | sudo tee /etc/profile.d/k3s-aliases.sh
sudo chmod +x /etc/profile.d/k3s-aliases.sh

sudo apt install -y net-tools
export PATH=${PATH}:/sbin

echo "PATH=$PATH" >> /etc/profile.d/k3s-path.sh