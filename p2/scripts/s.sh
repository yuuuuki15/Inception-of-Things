#!/bin/bash
echo "[INFO]  setting up k3s server"
sudo apt update -y
sudo apt install -y curl

echo "[INFO]  installing k3s server"
export INSTALL_K3S_EXEC="server --flannel-iface=eth1 --write-kubeconfig-mode 644"
curl -sfL https://get.k3s.io | sh -s -
echo "[INFO]  k3s server installed"

echo 'alias k="kubectl"' | sudo tee /etc/profile.d/k3s-aliases.sh
sudo chmod +x /etc/profile.d/k3s-aliases.sh

sudo apt install -y net-tools
export PATH=${PATH}:/sbin

echo "PATH=$PATH" >> /etc/profile.d/k3s-path.sh

# setting ufw
echo "[INFO]  Setting up firewall rules for k3s"
sudo apt install -y ufw
sudo ufw allow ssh
sudo ufw allow 6443/tcp  # Kubernetes API
sudo ufw allow 8472/udp  # Flannel VXLAN
sudo ufw allow 10250/tcp # Kubelet metrics
# sudo ufw allow 2379:2380/tcp # Only needed for HA with embedded etcd
# Block external access to VXLAN port (if VM has public interface)
sudo ufw deny in on eth0 to any port 8472
sudo ufw --force enable
echo "[INFO]  Firewall configured"

# set up namespace
echo "[INFO]  setting up namespace"
kubectl apply -f /vagrant/shared/yaml/namespace.yaml
echo "[INFO]  namespace set up"

# set up configmap
# echo "[INFO]  setting up config map"
# kubectl apply -f /vagrant/shared/yaml/configMap.yaml
# echo "[INFO]  config map set up"

# set up deployment
echo "[INFO]  setting up deployment"
kubectl apply -f /vagrant/shared/yaml/deployment.yaml
echo "[INFO]  deployment set up"

# set up service
echo "[INFO]  setting up service"
kubectl apply -f /vagrant/shared/yaml/service.yaml
echo "[INFO]  service set up"

# set up ingress
echo "[INFO]  setting up ingress"
kubectl apply -f /vagrant/shared/yaml/ingress.yaml
echo "[INFO]  ingress set up"