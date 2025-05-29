#!/bin/bash
# Set up Worker machine
SERVER_IP_ADDRESS="192.168.56.110"
K3S_SERVER_URL="https://${SERVER_IP_ADDRESS}:6443"
K3S_TOKEN_PATH="/vagrant/shared/node-token"

apt update && apt install -y curl vim

curl -sfL https://get.k3s.io | K3S_URL=${K3S_SERVER_URL} K3S_TOKEN=$(cat ${K3S_TOKEN_PATH}) sh -
