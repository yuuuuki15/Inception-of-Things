#!/bin/bash

# check permission
check_permission() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be run as root. Please use 'sudo'."
        exit 1
    fi
}

check_permission
