#!/bin/bash
# Generate Ansible Inventory from Terraform Outputs
# Run this script after terraform apply to populate the Ansible inventory

set -e

echo "Generating Ansible inventory from Terraform outputs..."

# Change to infra directory
cd "$(dirname "$0")/../infra" || exit 1

# Get Terraform outputs
EC2_IPS=$(terraform output -json ec2_public_ips | jq -r '.[]')
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
RDS_ADDRESS=$(terraform output -raw rds_address)
DB_USERNAME=$(terraform output -raw rds_username)
DB_NAME=$(terraform output -raw rds_database_name)

# Create inventory file
INVENTORY_FILE="../ansible/inventory/hosts.ini"

echo "Writing to $INVENTORY_FILE..."

cat > "$INVENTORY_FILE" <<EOF
# Auto-generated Ansible Inventory
# Generated on: $(date)

[ec2_instances]
EOF

# Add EC2 instances
counter=1
for ip in $EC2_IPS; do
    echo "ec2-$counter ansible_host=$ip" >> "$INVENTORY_FILE"
    ((counter++))
done

cat >> "$INVENTORY_FILE" <<EOF

[ec2_instances:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

[app_servers]
EOF

# Add app servers (same as EC2 instances)
counter=1
for ip in $EC2_IPS; do
    echo "ec2-$counter ansible_host=$ip" >> "$INVENTORY_FILE"
    ((counter++))
done

cat >> "$INVENTORY_FILE" <<EOF

[app_servers:vars]
app_name=devops-mid
app_port=5000
db_host=$RDS_ADDRESS
db_port=5432
db_name=$DB_NAME
db_user=$DB_USERNAME

[all:vars]
ansible_connection=ssh
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

echo "✅ Inventory file generated successfully!"
echo ""
echo "EC2 Instances:"
for ip in $EC2_IPS; do
    echo "  - $ip"
done
echo ""
echo "RDS Endpoint: $RDS_ENDPOINT"
echo ""
echo "You can now run: cd ../ansible && ansible-playbook -i inventory/hosts.ini playbook.yaml"
