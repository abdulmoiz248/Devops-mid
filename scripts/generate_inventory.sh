#!/bin/bash
# Generate Ansible Inventory from Terraform Outputs
# Run this script after terraform apply to populate the Ansible inventory

set -e

echo "Generating Ansible inventory from Terraform outputs..."

# Change to infra directory
cd "$(dirname "$0")/../infra" || exit 1

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "⚠️  Terraform not initialized. Running terraform init..."
    terraform init
fi

# Check if outputs exist
if ! terraform output -json ec2_public_ips > /dev/null 2>&1; then
    echo "❌ Error: Terraform outputs not found!"
    echo "   Please run 'terraform apply' first to create infrastructure."
    exit 1
fi

# Get Terraform outputs with error handling
EC2_IPS=$(terraform output -json ec2_public_ips 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "")
RDS_ENDPOINT=$(terraform output -raw rds_endpoint 2>/dev/null || echo "")
RDS_ADDRESS=$(terraform output -raw rds_address 2>/dev/null || echo "")
DB_USERNAME=$(terraform output -raw rds_username 2>/dev/null || echo "dbadmin")
DB_NAME=$(terraform output -raw rds_database_name 2>/dev/null || echo "devopsdb")

# Validate EC2 IPs
if [ -z "$EC2_IPS" ] || [ "$EC2_IPS" = "null" ]; then
    echo "⚠️  Warning: No EC2 instances found in Terraform outputs!"
    echo "   The inventory will be created but will be empty."
    EC2_IPS=""
fi

# Create inventory file
INVENTORY_FILE="../ansible/inventory/hosts.ini"

echo "Writing to $INVENTORY_FILE..."

cat > "$INVENTORY_FILE" <<EOF
# Auto-generated Ansible Inventory
# Generated on: $(date)

[ec2_instances]
EOF

# Add EC2 instances
if [ -n "$EC2_IPS" ]; then
    counter=1
    for ip in $EC2_IPS; do
        if [ -n "$ip" ] && [ "$ip" != "null" ]; then
            echo "ec2-$counter ansible_host=$ip" >> "$INVENTORY_FILE"
            ((counter++))
        fi
    done
fi

cat >> "$INVENTORY_FILE" <<EOF

[ec2_instances:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

[app_servers]
EOF

# Add app servers (same as EC2 instances)
if [ -n "$EC2_IPS" ]; then
    counter=1
    for ip in $EC2_IPS; do
        if [ -n "$ip" ] && [ "$ip" != "null" ]; then
            echo "ec2-$counter ansible_host=$ip" >> "$INVENTORY_FILE"
            ((counter++))
        fi
    done
fi

cat >> "$INVENTORY_FILE" <<EOF

[app_servers:vars]
app_name=devops-mid
app_port=5000
db_host=${RDS_ADDRESS:-}
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
