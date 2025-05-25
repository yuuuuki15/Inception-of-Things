# Virtual Machine set-up

The assignment requires the project to run in a virtual machine. We will use the **Ubuntu 24.04** release to create a VirtualBox VM.

## Requirements

- VirtualBox

## How To

1. Download the Ubuntu image from the official website.

2. Run VirtualBox. Create a new virtual machine using the **Ubuntu ISO**.

3. Create the user profile and define the virtual machine's resources. Once done, start it, install Ubuntu, and re-start the virtual machine.

4. Update the package index and upgrade installed packages:

   ```sh
   $ sudo apt update && sudo apt upgrade
   ```

5. Install any necessary tools. For example, VirtualBox Guest Additions, or `curl` and `git`:

   ```sh
   $ sudo apt install curl git
   ```

6. Install **Vagrant** ([official documentation here](https://developer.hashicorp.com/vagrant/install#linux)):

   ```sh
   $ wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
   $ echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
   $ sudo apt update && sudo apt install vagrant
   ```

7. Install **k3s** ([official documentation here](https://docs.k3s.io/quick-start)):

   ```sh
   $ curl -sfL https://get.k3s.io | sh -
   ```

8. Install **k3d** ([official documentation here](https://k3d.io/stable/#installation)):

   ```sh
   $ curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
   ```
