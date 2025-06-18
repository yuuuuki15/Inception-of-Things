#!/bin/bash'

set -e

sudo kubectl apply -f configs/dev/app.yaml --namespace argocd
sudo kubectl apply -f configs/dev/ingress.yaml --namespace dev
