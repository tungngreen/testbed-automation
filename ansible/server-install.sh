#!/bin/bash

hostname=${1}

read -p "Please enter the vault password: " vault_password

### SSH setup
/bin/bash hosts/populate_known_hosts.sh inventory/hosts

### If host name is all, run the playbook for all hosts without "--limit"
if hostname == "all"; then
  limit=""
else
  limit="--limit ${hostname}"
fi

ansible-playbook -i inventory/hosts server-install.yml --ask-vault-pass ${limit}

