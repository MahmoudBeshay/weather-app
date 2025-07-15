#!/bin/bash
cd terraform
 
BASTION_IP=$(terraform output -raw bastion_public_ip)
PRIVATE_IPS=($(terraform output -json k8s_private_ips | jq -r '.[]'))
 
cat > ../ansible/ansible-playbook/inventory.ini <<EOF
[bastion]
bastion ansible_host=$BASTION_IP ansible_user=ubuntu ansible_ssh_private_key_file=../k8s-key.pem
[k8s_master]
master ansible_host=${PRIVATE_IPS[0]} ansible_user=ubuntu ansible_ssh_common_args='-o ProxyCommand="ssh -i ../k8s-key.pem -W %h:%p ubuntu@$BASTION_IP"' ansible_ssh_private_key_file=../k8s-key.pem

[k8s_workers]
worker1 ansible_host=${PRIVATE_IPS[1]} ansible_user=ubuntu ansible_ssh_common_args='-o ProxyCommand="ssh -i ../k8s-key.pem -W %h:%p ubuntu@$BASTION_IP"' ansible_ssh_private_key_file=../k8s-key.pem
worker2 ansible_host=${PRIVATE_IPS[2]} ansible_user=ubuntu ansible_ssh_common_args='-o ProxyCommand="ssh -i ../k8s-key.pem -W %h:%p ubuntu@$BASTION_IP"' ansible_ssh_private_key_file=../k8s-key.pem
EOF
