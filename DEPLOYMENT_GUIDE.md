# Complete Deployment Guide - Terraform + Ansible

This guide provides step-by-step instructions for deploying the DevOps Mid project using Terraform and Ansible on AWS Free Tier.

## 📋 Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Terraform Deployment](#terraform-deployment)
4. [Ansible Configuration](#ansible-configuration)
5. [Verification](#verification)
6. [Screenshots for Assignment](#screenshots-for-assignment)
7. [Cleanup](#cleanup)
8. [Troubleshooting](#troubleshooting)

## 🎯 Prerequisites

### Required Software

- [x] **AWS Account** (Free Tier eligible)
- [x] **AWS CLI** configured with credentials
- [x] **Terraform** >= 1.0
- [x] **Ansible** >= 2.14
- [x] **Python 3.8+**
- [x] **Git**
- [x] **SSH key pair**

### Installation Commands

**On Windows (PowerShell):**
```powershell
# Install Chocolatey (if not installed)
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install required tools
choco install terraform awscli python git -y

# Install Ansible via pip
pip install ansible

# Verify installations
terraform --version
aws --version
ansible --version
python --version
```

**On Linux/macOS:**
```bash
# Install Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Ansible
pip3 install ansible

# Verify installations
terraform --version
aws --version
ansible --version
```

## 🔧 Initial Setup

### Step 1: Configure AWS Credentials

```bash
# Configure AWS CLI
aws configure

# Enter your credentials:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### Step 2: Generate SSH Key Pair

```bash
# Generate new SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Verify key exists
ls -la ~/.ssh/id_rsa*
```

### Step 3: Clone/Navigate to Project

```bash
cd C:\Users\Admin\Desktop\Devops-mid
# or your project directory
```

## 🏗️ Terraform Deployment

### Step 1: Configure Variables

```bash
cd infra

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars
# On Windows: notepad terraform.tfvars
# On Linux: nano terraform.tfvars
```

**Update these values in `terraform.tfvars`:**

```hcl
aws_region = "us-east-1"
project_name = "devops-mid"
environment = "production"

# EC2 Configuration (FREE TIER)
ec2_instance_count = 1
ec2_instance_type  = "t2.micro"

# RDS Configuration (FREE TIER)
db_instance_class = "db.t3.micro"
db_name          = "devopsdb"
db_username      = "dbadmin"
db_password      = "YourSecurePassword123!"  # CHANGE THIS!

# Cost Optimization (IMPORTANT!)
create_nat_gateway = false  # Saves ~$32/month
create_alb         = false  # Saves ~$16/month

# Security
allowed_ssh_cidr = ["YOUR_PUBLIC_IP/32"]  # Get from: curl ifconfig.me
```

### Step 2: Initialize Terraform

```bash
# Initialize Terraform
terraform init

# Expected output:
# Terraform has been successfully initialized!
```

### Step 3: Validate Configuration

```bash
# Validate syntax
terraform validate

# Format files
terraform fmt

# Check what will be created
terraform plan

# Review the plan carefully!
# Should show: Plan: ~15-20 to add, 0 to change, 0 to destroy
```

### Step 4: Deploy Infrastructure

```bash
# Apply configuration
terraform apply

# Type 'yes' when prompted
# This takes ~10-15 minutes
```

**Expected output:**
```
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:

deployment_summary = {
  "alb_enabled" = false
  "application_url" = "http://XX.XX.XX.XX:5000"
  "ec2_count" = 1
  "ec2_public_ips" = [
    "XX.XX.XX.XX",
  ]
  ...
}
```

### Step 5: Save Terraform Outputs

```bash
# Save outputs to file (for assignment report)
terraform output > ../outputs/terraform-output.txt
terraform output -json > ../outputs/terraform-output.json

# Get specific values
terraform output ec2_public_ips
terraform output rds_endpoint
```

## 🤖 Ansible Configuration

### Step 1: Install Ansible Dependencies

```bash
cd ../ansible

# Install Python packages
pip install -r requirements.txt

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml

# Verify installation
ansible --version
ansible-galaxy collection list
```

### Step 2: Generate Inventory

**Option A: Automatic (Recommended)**

```powershell
# On Windows PowerShell
cd ..\scripts
.\generate_inventory.ps1
```

```bash
# On Linux/macOS
cd ../scripts
chmod +x generate_inventory.sh
./generate_inventory.sh
```

**Option B: Manual**

Edit `ansible/inventory/hosts.ini`:

```ini
[ec2_instances]
ec2-1 ansible_host=YOUR_EC2_PUBLIC_IP

[ec2_instances:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

[app_servers]
ec2-1 ansible_host=YOUR_EC2_PUBLIC_IP

[app_servers:vars]
app_name=devops-mid
app_port=5000
db_host=YOUR_RDS_ENDPOINT
db_port=5432
db_name=devopsdb
db_user=dbadmin

[all:vars]
ansible_connection=ssh
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

### Step 3: Test Connectivity

```bash
cd ../ansible

# Test SSH connection
ansible all -m ping -i inventory/hosts.ini

# Expected output:
# ec2-1 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }

# Run connectivity test playbook
ansible-playbook -i inventory/hosts.ini test-connection.yaml
```

### Step 4: Run Main Playbook

```bash
# Run the full playbook
ansible-playbook -i inventory/hosts.ini playbook.yaml

# With verbose output (recommended for assignment)
ansible-playbook -i inventory/hosts.ini playbook.yaml -v

# This takes ~5-10 minutes
```

**Expected output:**
```
PLAY RECAP *********************************************************************
ec2-1 : ok=XX   changed=XX   unreachable=0    failed=0    skipped=X    rescued=0    ignored=0
```

### Step 5: Verify Installation

```bash
# Check Docker installation
ansible ec2_instances -i inventory/hosts.ini -a "docker --version"

# Check Docker Compose
ansible ec2_instances -i inventory/hosts.ini -a "docker-compose --version"

# Check Docker service status
ansible ec2_instances -i inventory/hosts.ini -a "systemctl status docker" -b

# Check PostgreSQL client
ansible ec2_instances -i inventory/hosts.ini -a "psql --version"
```

## ✅ Verification

### 1. SSH to EC2 Instance

```bash
# Get IP from Terraform output
ssh -i ~/.ssh/id_rsa ec2-user@YOUR_EC2_IP

# Once connected, verify:
docker --version
docker-compose --version
python3 --version
ls -la /opt/app
```

### 2. Check Docker

```bash
# On EC2 instance
sudo systemctl status docker
docker ps
docker images
```

### 3. Test Database Connection

```bash
# On EC2 instance
psql -h YOUR_RDS_ENDPOINT -U dbadmin -d devopsdb

# Enter password when prompted
# If successful, you'll see PostgreSQL prompt
```

### 4. Check Application Directory

```bash
# On EC2 instance
ls -la /opt/app
cat /opt/app/.env
./opt/app/health_check.sh
```

## 📸 Screenshots for Assignment

### Terraform Screenshots

1. **Terraform Plan**
   ```bash
   cd infra
   terraform plan > terraform-plan.txt
   # Screenshot: Terminal showing plan output
   ```

2. **Terraform Apply**
   ```bash
   terraform apply
   # Screenshot: Terminal showing "Apply complete!" message
   ```

3. **Terraform Output**
   ```bash
   terraform output
   # Screenshot: All outputs displayed
   ```

4. **AWS Console - EC2**
   - Navigate to EC2 Dashboard
   - Screenshot: Running instances
   - Screenshot: Security groups

5. **AWS Console - VPC**
   - Navigate to VPC Dashboard
   - Screenshot: VPC, subnets, route tables

6. **AWS Console - RDS**
   - Navigate to RDS Dashboard
   - Screenshot: Database instance running

### Ansible Screenshots

1. **Ansible Inventory**
   ```bash
   cd ansible
   ansible-inventory -i inventory/hosts.ini --list
   # Screenshot: Inventory output
   ```

2. **Ansible Ping**
   ```bash
   ansible all -m ping -i inventory/hosts.ini
   # Screenshot: Successful ping response
   ```

3. **Ansible Playbook Run**
   ```bash
   ansible-playbook -i inventory/hosts.ini playbook.yaml
   # Screenshot: Full playbook execution
   # Screenshot: PLAY RECAP showing success
   ```

4. **Ansible Verification**
   ```bash
   ansible ec2_instances -i inventory/hosts.ini -a "docker --version"
   ansible ec2_instances -i inventory/hosts.ini -a "systemctl status docker" -b
   # Screenshot: Command outputs
   ```

### Additional Screenshots

1. **SSH Connection**
   ```bash
   ssh -i ~/.ssh/id_rsa ec2-user@YOUR_EC2_IP
   docker ps
   # Screenshot: Inside EC2 instance
   ```

2. **File Structure**
   ```bash
   tree infra/
   tree ansible/
   # Screenshot: Directory structure
   ```

## 🧹 Cleanup

### Important: Destroy All Resources

To avoid charges, destroy all resources when done:

```bash
# Navigate to infra directory
cd infra

# Preview what will be destroyed
terraform plan -destroy

# Destroy all resources
terraform destroy

# Type 'yes' when prompted
# This takes ~10 minutes
```

**Verify cleanup in AWS Console:**
- [ ] EC2 instances terminated
- [ ] RDS database deleted
- [ ] VPC deleted
- [ ] Security groups deleted
- [ ] Elastic IPs released

### Take Destroy Screenshot

```bash
# Screenshot: Terminal showing "Destroy complete!"
# Screenshot: AWS Console showing no resources
```

## 🔧 Troubleshooting

### Terraform Issues

**Error: "InvalidKeyPair.NotFound"**
```bash
# Update ec2.tf with correct key path
# Or create key in AWS console and import:
aws ec2 import-key-pair --key-name devops-mid-key --public-key-material fileb://~/.ssh/id_rsa.pub
```

**Error: "VPC limit exceeded"**
```bash
# Delete unused VPCs
aws ec2 describe-vpcs
aws ec2 delete-vpc --vpc-id vpc-xxxxx
```

**Error: "UnauthorizedOperation"**
```bash
# Check AWS credentials
aws sts get-caller-identity

# Reconfigure if needed
aws configure
```

### Ansible Issues

**Error: "Connection timeout"**
```bash
# Check security group allows SSH
# Verify EC2 is running
# Test manual SSH:
ssh -i ~/.ssh/id_rsa ec2-user@YOUR_EC2_IP
```

**Error: "Permission denied (publickey)"**
```bash
# Fix key permissions
chmod 600 ~/.ssh/id_rsa

# Verify key path in ansible.cfg
```

**Error: "Module not found"**
```bash
# Reinstall collections
ansible-galaxy collection install -r requirements.yml --force
```

### AWS Free Tier Issues

**Unexpected Charges?**
```bash
# Check what's running
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name]'
aws rds describe-db-instances

# Immediately destroy if needed
cd infra
terraform destroy -auto-approve
```

## 📚 Quick Reference

### Common Terraform Commands

```bash
terraform init          # Initialize
terraform validate      # Validate syntax
terraform plan          # Preview changes
terraform apply         # Deploy
terraform destroy       # Delete all
terraform output        # Show outputs
terraform state list    # List resources
terraform fmt           # Format files
```

### Common Ansible Commands

```bash
ansible all -m ping -i inventory/hosts.ini              # Test connectivity
ansible-playbook playbook.yaml -i inventory/hosts.ini   # Run playbook
ansible-playbook playbook.yaml --check                  # Dry run
ansible-playbook playbook.yaml --tags docker            # Run specific tags
ansible all -a "command" -i inventory/hosts.ini         # Ad-hoc command
ansible-inventory --list -i inventory/hosts.ini         # Show inventory
```

### AWS CLI Quick Commands

```bash
aws ec2 describe-instances                    # List EC2 instances
aws rds describe-db-instances                 # List RDS instances
aws ec2 describe-vpcs                         # List VPCs
aws ec2 describe-security-groups              # List security groups
aws sts get-caller-identity                   # Check credentials
```

## 🎓 Assignment Checklist

### Step 2: Terraform Infrastructure [10 Marks]

- [x] Created `infra/` folder with .tf files
- [ ] Run `terraform plan` and save output
- [ ] Run `terraform apply` successfully
- [ ] Take screenshot of `terraform output`
- [ ] Take screenshot of AWS Console (EC2, VPC, RDS)
- [ ] Run `terraform destroy` and take screenshot
- [ ] Document all steps in report

### Step 4: Ansible Configuration [5 Marks]

- [x] Created `ansible/playbook.yaml`
- [x] Created inventory file `ansible/inventory/hosts.ini`
- [ ] Install Ansible dependencies
- [ ] Run `ansible all -m ping` successfully
- [ ] Run `ansible-playbook playbook.yaml` successfully
- [ ] Take screenshot of playbook execution
- [ ] Take screenshot of PLAY RECAP
- [ ] Verify Docker installed on EC2
- [ ] Document all steps in report

## 🎯 Expected Outcomes

After completing this guide:

✅ VPC with public and private subnets created
✅ 1 EC2 instance (t2.micro) running
✅ RDS PostgreSQL database (db.t3.micro) created
✅ Security groups configured
✅ Docker and Docker Compose installed on EC2
✅ PostgreSQL client installed
✅ Application directories created
✅ All configurations automated via Ansible
✅ Total cost: $0 (within free tier)

## 📞 Support Resources

- **Terraform Docs:** https://www.terraform.io/docs
- **Ansible Docs:** https://docs.ansible.com
- **AWS Free Tier:** https://aws.amazon.com/free
- **AWS CLI Docs:** https://docs.aws.amazon.com/cli

---

**Good luck with your DevOps assignment! 🚀**
