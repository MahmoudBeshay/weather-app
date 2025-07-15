#!/bin/bash
set -e

# Go into terraform directory
cd terraform

# Check jq exists (required for Terraform output parsing)
if ! command -v jq &>/dev/null; then
  echo " 'jq' is not installed. Please install it before running this script."
  exit 1
fi

# Fetch bastion public IP and private IPs of k8s nodes
BASTION_IP=$(terraform output -raw bastion_public_ip)
PRIVATE_IPS=($(terraform output -json k8s_private_ips | jq -r '.[]'))

# Go back to project root
cd ..

# Ensure output directory exists
mkdir -p ansible/ansible-playbook

# Write inventory file
cat > ansible/ansible-playbook/inventory.ini <<EOF
[bastion]
bastion ansible_host=$BASTION_IP ansible_user=ubuntu ansible_ssh_private_key_file=../k8s.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[k8s_master]
master ansible_host=${PRIVATE_IPS[0]} ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -i ../k8s.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ubuntu@$BASTION_IP"' ansible_ssh_private_key_file=../k8s.pem

[k8s_workers]
worker1 ansible_host=${PRIVATE_IPS[1]} ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -i ../k8s.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ubuntu@$BASTION_IP"' ansible_ssh_private_key_file=../k8s.pem

worker2 ansible_host=${PRIVATE_IPS[2]} ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ProxyCommand="ssh -i ../k8s.pem -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p ubuntu@$BASTION_IP"' ansible_ssh_private_key_file=../k8s.pem
EOF

echo "Dynamic Ansible inventory generated at: ansible/ansible-playbook/inventory.ini"
