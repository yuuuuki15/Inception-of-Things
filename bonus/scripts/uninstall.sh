#!/bin/bash

# destroy cluster
sudo k3d cluster delete bonus

# remove argocd and gitlab DNS entry from /etc/hosts(create backup named /etc/hosts.bak)
sudo sed -i.bak -e '/^127\.0\.0\.1\s\+argocd\.local$/d' -e '/^127\.0\.0\.1\s\+gitlab\.local$/d' /etc/hosts
