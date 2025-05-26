#!/bin/bash
echo "[INFO]  setting up k3s server"
sudo apt update -y
sudo apt install -y curl

echo "[INFO]  installing k3s server"
export INSTALL_K3S_EXEC="server --flannel-iface=eth1 --write-kubeconfig-mode 644"
curl -sfL https://get.k3s.io | sh -s -
echo "[INFO]  k3s server installed"

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/shared/node-token
echo "[INFO]  node-token copied to /vagrant/shared/node-token"

echo 'alias k="kubectl"' | sudo tee /etc/profile.d/k3s-aliases.sh
sudo chmod +x /etc/profile.d/k3s-aliases.sh

sudo apt install -y net-tools
export PATH=${PATH}:/sbin

echo "PATH=$PATH" >> /etc/profile.d/k3s-path.sh