#!/bin/bash

hostname=${1}

read -p "Please enter the vault password: " vault_password

### SSH setup
/bin/bash ssh/populate_known_hosts.sh
echo ${vault_password} | ansible-playbook -i inventory/hosts ssh/populate_server_ssh_keys.yml --ask-vault-pass --limit ${hostname}

### Setup fish
echo ${vault_password} | ansible-playbook -i inventory/hosts fish/fish-setup.yml --ask-vault-pass --limit ${hostname}

### Docker setup
echo ${vault_password} | ansible-playbook -i inventory/hosts docker-setup/setup.yml --ask-vault-pass --limit ${hostname}

### NVIDIA CUDA, CUDNN setup
echo ${vault_password} | ansible-playbook -i inventory/hosts nvidia/cuda_server.yml --ask-vault-pass --limit ${hostname}
echo ${vault_password} | ansible-playbook -i inventory/hosts nvidia/cudnn_server.yml --ask-vault-pass --limit ${hostname}
### NVIDIA Docker setup
echo ${vault_password} | ansible-playbook -i inventory/hosts nvidia/nvidia-toolkit_server.yml --ask-vault-pass --limit ${hostname}
echo ${vault_password} | ansible-playbook -i inventory/hosts nvidia/configure_docker_daemon.yml --ask-vault-pass --limit ${hostname}



