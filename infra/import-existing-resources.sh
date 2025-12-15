#!/bin/bash
# Script to import existing AWS resources into Terraform state
# This prevents "already exists" errors when running terraform apply

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_NAME="devops-mid"

echo -e "${YELLOW}🔄 Importing existing AWS resources into Terraform state...${NC}\n"

# Clean up DB subnet group if it exists (to avoid VPC mismatch)
echo -e "${YELLOW}Cleaning up old DB subnet group...${NC}"
aws rds delete-db-subnet-group --db-subnet-group-name "${PROJECT_NAME}-db-subnet-group" 2>/dev/null || echo -e "${YELLOW}DB subnet group doesn't exist${NC}"
echo "Waiting for deletion..."
sleep 10
echo ""

# Function to import a resource
import_resource() {
    local resource_type=$1
    local resource_name=$2
    local resource_id=$3
    
    echo -e "${YELLOW}Checking ${resource_type}...${NC}"
    
    if terraform import "$resource_name" "$resource_id" 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully imported: $resource_type${NC}\n"
    else
        echo -e "${YELLOW}⚠️  Resource doesn't exist in AWS or already in Terraform state: $resource_type${NC}\n"
    fi
}

# Import EC2 Key Pair
import_resource \
    "EC2 Key Pair" \
    "aws_key_pair.deployer" \
    "${PROJECT_NAME}-key"

# Note: DB Subnet Group is NOT imported - it will be created fresh with correct VPC
echo -e "${YELLOW}ℹ️  DB Subnet Group will be created fresh (not imported)${NC}\n"

# Optional: Import other resources if needed
# Uncomment and modify as needed:

# import_resource \
#     "RDS Instance" \
#     "aws_db_instance.postgres" \
#     "${PROJECT_NAME}-postgres"

echo -e "${GREEN}✅ Import process completed!${NC}"
echo -e "${YELLOW}You can now run 'terraform plan' and 'terraform apply' safely.${NC}"
