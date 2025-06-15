# Virtual Machine set-up

The assignment requires the project to run in a virtual machine. We will use the **Ubuntu 24.04** release to create a VirtualBox VM.

## Requirements

- VirtualBox

## How To

1. Download the Ubuntu image from the official website.

2. Run VirtualBox. Create a new virtual machine using the **Ubuntu ISO**.

3. Create the user profile and define the virtual machine's resources. Once done, start it, install Ubuntu, and restart the virtual machine.

4. Update the package index and upgrade installed packages:

   ```sh
   $ sudo apt update && sudo apt upgrade
   ```

5. Install any necessary tools. For example, VirtualBox Guest Additions, or `curl`, `git` and `vim`:

   ```sh
   $ sudo apt install curl git vim
   ```

6. Install **Vagrant** ([official documentation here](https://developer.hashicorp.com/vagrant/install#linux)):

   ```sh
   $ wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   $ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   $ sudo apt update && sudo apt install vagrant
   ```

7. Install **Docker**. The following steps come from the [official installation guide for Ubuntu](https://docs.docker.com/engine/install/ubuntu/).

   Set up Docker's `apt` repository:

   ```sh
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
   ```

   Install the Docker packages:
   ```sh
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

8. To install **k3d**, follow the [official documentation](https://k3d.io/stable/#installation):

   ```sh
   $ curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
   ```

9. Stop the virtual machine.

10. In the marchine's settings > System > Processor, check "Enable Nested VT-x/AMD-V" to enable nested virtualization.

11. Take a **snapshot** just in case you need to restore a clean virtual machine.
