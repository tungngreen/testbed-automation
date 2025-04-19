#!/bin/bash
# create_vault.sh

echo "Creating secure credential vault"
echo "-------------------------------"

# Get inventory path
read -p "Enter path to inventory file [default: /etc/ansible/hosts]: " INVENTORY_PATH
INVENTORY_PATH=${INVENTORY_PATH:-/etc/ansible/hosts}

if [ ! -f "$INVENTORY_PATH" ]; then
  echo "Error: Inventory file not found at $INVENTORY_PATH"
  exit 1
fi

# Prompt for vault password
read -sp "Enter vault password: " VAULT_PASS
echo

# Create temporary file with prompted credentials
echo "Adding credentials to vault (input will be hidden)"
echo "---" > temp_creds.yml
echo "credentials:" >> temp_creds.yml

# Extract hosts from inventory file (excluding comments and empty lines)
HOSTS=$(grep -v "^#\|^$\|^\[" "$INVENTORY_PATH" | awk '{print $1}' | sort | uniq)

# Function to add hosts
add_host() {
  echo "  $1:" >> temp_creds.yml
  read -p "  Username for $1: " USERNAME
  echo -n "  Password for $1: "
  read -rs PASSWORD
  echo
  
  echo "    user: $USERNAME" >> temp_creds.yml
  
  # Special handling for space character password
  if [ "$PASSWORD" = " " ]; then
    echo "    password: ' '" >> temp_creds.yml
    echo "    space_password: true" >> temp_creds.yml
  else
    echo "    password: '$PASSWORD'" >> temp_creds.yml
    echo "    space_password: false" >> temp_creds.yml
  fi
}

# Add all hosts from inventory
for HOST in $HOSTS; do
  echo "Adding host: $HOST"
  add_host "$HOST"
done

# Add more hosts manually?
while true; do
  read -p "Add another host not in inventory? (y/n): " MORE
  if [ "$MORE" != "y" ]; then
    break
  fi
  read -p "Hostname: " HOSTNAME
  add_host "$HOSTNAME"
done

# Encrypt the file
echo "$VAULT_PASS" | ansible-vault encrypt temp_creds.yml --output credentials.yml --vault-password-file=/bin/cat
rm temp_creds.yml

echo "Vault created as credentials.yml"
