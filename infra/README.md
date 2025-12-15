# Terraform AWS Infrastructure

This Terraform configuration provisions a complete AWS infrastructure including:
- VPC with public and private subnets
- EC2 instances with Application Load Balancer
- RDS PostgreSQL database
- Security groups and networking

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                         VPC (10.0.0.0/16)                    │
│                                                               │
│  ┌───────────────────────┐  ┌──────────────────────────┐    │
│  │  Public Subnet 1      │  │  Public Subnet 2         │    │
│  │  (10.0.1.0/24)        │  │  (10.0.2.0/24)          │    │
│  │                       │  │                          │    │
│  │  ┌──────────┐         │  │         ┌──────────┐    │    │
│  │  │  EC2-1   │         │  │         │  EC2-2   │    │    │
│  │  └──────────┘         │  │         └──────────┘    │    │
│  │       │               │  │              │           │    │
│  └───────┼───────────────┘  └──────────────┼───────────┘    │
│          │                                  │                │
│          └──────────────┬───────────────────┘                │
│                         │                                    │
│                  ┌──────▼──────┐                            │
│                  │     ALB     │ ◄─── Internet              │
│                  └─────────────┘                            │
│                                                               │
│  ┌───────────────────────┐  ┌──────────────────────────┐    │
│  │  Private Subnet 1     │  │  Private Subnet 2        │    │
│  │  (10.0.11.0/24)       │  │  (10.0.12.0/24)         │    │
│  │                       │  │                          │    │
│  │  ┌──────────────┐     │  │                          │    │
│  │  │ RDS PostgreSQL │    │  │                          │    │
│  │  └──────────────┘     │  │                          │    │
│  └───────────────────────┘  └──────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **AWS CLI** - Installed and configured
   ```bash
   aws configure
   ```

2. **Terraform** - Version >= 1.0
   ```bash
   # Download from: https://www.terraform.io/downloads
   terraform --version
   ```

3. **SSH Key Pair** - Generate if you don't have one
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```

## Configuration

### 1. Create terraform.tfvars file

Create a `terraform.tfvars` file in the `infra/` directory:

```hcl
# terraform.tfvars
aws_region         = "us-east-1"
project_name       = "devops-mid"
environment        = "production"
ec2_instance_count = 2
ec2_instance_type  = "t2.micro"
db_instance_class  = "db.t3.micro"
db_name            = "devopsdb"
db_username        = "dbadmin"
db_password        = "YourStrongPassword123!"  # Change this!
allowed_ssh_cidr   = ["YOUR_IP_ADDRESS/32"]    # Change to your IP
```

### 2. Update EC2 Key Path (if needed)

Edit `infra/ec2.tf` line 22 to point to your SSH public key:
```hcl
public_key = file("~/.ssh/id_rsa.pub")
```

## Deployment Steps

### Step 1: Initialize Terraform

```bash
cd infra
terraform init
```

This downloads required providers and initializes the backend.

### Step 2: Validate Configuration

```bash
terraform validate
```

### Step 3: Plan Infrastructure

```bash
terraform plan
```

Review the planned changes. Terraform will show you what resources will be created.

### Step 4: Apply Configuration

```bash
terraform apply
```

Type `yes` when prompted. This will take approximately 10-15 minutes to provision all resources.

### Step 5: View Outputs

```bash
terraform output
```

This displays all provisioned resources including:
- EC2 public IPs
- Load Balancer DNS name
- RDS endpoint
- SSH connection commands

## Accessing Resources

### SSH to EC2 Instances

```bash
# Get SSH commands from output
terraform output ssh_connection_commands

# Example:
ssh -i ~/.ssh/id_rsa ec2-user@<EC2_PUBLIC_IP>
```

### Access Application

```bash
# Get ALB DNS
terraform output alb_dns_name

# Access in browser:
http://<ALB_DNS_NAME>
```

### Connect to RDS Database

From EC2 instance:
```bash
# Install PostgreSQL client
sudo yum install -y postgresql15

# Get RDS endpoint
terraform output rds_endpoint

# Connect
psql -h <RDS_ENDPOINT> -U dbadmin -d devopsdb
```

## Viewing Resources in AWS Console

1. **VPC**: Navigate to VPC Dashboard
   - VPC: `devops-mid-vpc`
   - Subnets: 2 public, 2 private
   - Internet Gateway, NAT Gateway, Route Tables

2. **EC2**: Navigate to EC2 Dashboard
   - Instances: `devops-mid-ec2-1`, `devops-mid-ec2-2`
   - Load Balancers: `devops-mid-alb`
   - Target Groups: `devops-mid-tg`
   - Security Groups: `devops-mid-ec2-sg`, `devops-mid-alb-sg`

3. **RDS**: Navigate to RDS Dashboard
   - Database: `devops-mid-postgres`
   - Security Group: `devops-mid-rds-sg`

## Resource Costs Estimate

**Free Tier eligible resources:**
- EC2 t2.micro instances (750 hours/month free)
- RDS db.t3.micro (750 hours/month free)
- 20GB RDS storage (free tier)

**Paid resources:**
- NAT Gateway: ~$0.045/hour (~$32/month)
- Application Load Balancer: ~$0.0225/hour (~$16/month)

**Estimated monthly cost:** ~$48 (excluding free tier benefits)

## Cleanup (Destroy Resources)

### WARNING: This will delete ALL resources!

```bash
# Plan destruction
terraform plan -destroy

# Destroy all resources
terraform destroy
```

Type `yes` when prompted.

### Verification of Cleanup

After running `terraform destroy`, verify in AWS Console that:
- All EC2 instances are terminated
- Load Balancer is deleted
- RDS instance is deleted
- VPC and subnets are deleted
- NAT Gateway and Elastic IP are released

## Taking Screenshots for Report

### 1. Before Deployment
```bash
terraform plan > terraform-plan.txt
```

### 2. Terraform Output
```bash
terraform output > terraform-output.txt
terraform output -json > terraform-output.json
```

### 3. AWS Console Screenshots

**VPC Dashboard:**
- Screenshot showing VPC, subnets, route tables

**EC2 Dashboard:**
- Screenshot showing running instances
- Screenshot showing load balancer
- Screenshot showing target groups

**RDS Dashboard:**
- Screenshot showing database instance

**Security Groups:**
- Screenshot showing all security groups

### 4. Destroy Proof
```bash
terraform destroy
# Take screenshot of terminal showing "Destroy complete!"
# Take screenshot of AWS Console showing no resources
```

## Troubleshooting

### Issue: "Error creating EC2 Instance"
**Solution:** Check that your AWS credentials have proper permissions.

### Issue: "InvalidKeyPair.NotFound"
**Solution:** Update the SSH key path in `ec2.tf` or create the key in AWS.

### Issue: "VPC limit exceeded"
**Solution:** Delete unused VPCs or request limit increase from AWS.

### Issue: "Database password too weak"
**Solution:** Use a strong password with uppercase, lowercase, numbers, and special characters.

### Issue: NAT Gateway timeout
**Solution:** NAT Gateway takes 3-5 minutes to provision. Wait and retry.

## File Structure

```
infra/
├── provider.tf           # AWS provider configuration
├── variables.tf          # Input variables
├── vpc.tf               # VPC, subnets, networking
├── security_groups.tf   # Security groups
├── ec2.tf               # EC2 instances and load balancer
├── rds.tf               # RDS PostgreSQL database
├── outputs.tf           # Output values
├── terraform.tfvars     # Variable values (create this)
└── README.md            # This file
```

## Additional Commands

### Format Terraform files
```bash
terraform fmt
```

### Show current state
```bash
terraform show
```

### List resources
```bash
terraform state list
```

### Get specific output
```bash
terraform output ec2_public_ips
terraform output alb_dns_name
terraform output rds_endpoint
```

## Security Best Practices

1. **Never commit `terraform.tfvars`** - Add to `.gitignore`
2. **Use strong passwords** for RDS
3. **Restrict SSH access** - Set `allowed_ssh_cidr` to your IP only
4. **Enable MFA** on your AWS account
5. **Use IAM roles** instead of access keys when possible
6. **Rotate credentials** regularly
7. **Enable CloudWatch logs** for monitoring

## Next Steps

After infrastructure is provisioned:

1. Deploy your application to EC2 instances
2. Configure environment variables with RDS credentials
3. Set up CI/CD pipeline for automated deployments
4. Configure SSL/TLS certificate for HTTPS
5. Set up monitoring and alerts
6. Configure backup strategy

## Support

For issues or questions:
1. Check AWS CloudWatch logs
2. Review Terraform error messages
3. Verify AWS service quotas
4. Check AWS service health dashboard

---

**Created for DevOps Mid Assignment - Step 2: Infrastructure Provisioning with Terraform**
