# AWS Free Tier Configuration Guide

This guide ensures all resources are configured to use AWS Free Tier eligible options.

## 🎯 Free Tier Resources

### What's Included in AWS Free Tier (12 Months)

✅ **EC2 Instances**
- 750 hours/month of t2.micro instances
- 1 instance = 750 hours, 2 instances = 375 hours each
- **Our config:** 1 t2.micro instance (default)

✅ **RDS Database**
- 750 hours/month of db.t3.micro instances
- 20GB of General Purpose (SSD) storage
- 20GB of backup storage
- **Our config:** 1 db.t3.micro with 20GB gp2 storage

✅ **Elastic Load Balancer**
- 750 hours/month
- 15GB data processing
- **Our config:** DISABLED by default (costs ~$16/month)

✅ **VPC and Networking**
- 1 Elastic IP (when associated with running instance)
- **Our config:** Elastic IPs on EC2 instances only

❌ **NOT Free Tier (Disabled by Default)**
- NAT Gateway: ~$32/month
- Application Load Balancer: ~$16/month when enabled
- gp3 storage: slightly more expensive than gp2
- Encrypted RDS storage

## 💰 Cost Optimization Settings

### In terraform.tfvars

```hcl
# EC2 Configuration - FREE TIER
ec2_instance_count = 1         # Use 1 for fully free
ec2_instance_type  = "t2.micro"  # Must be t2.micro

# RDS Configuration - FREE TIER  
db_instance_class = "db.t3.micro"  # Free tier eligible

# Cost Optimization - SAVE MONEY
create_nat_gateway = false  # Saves ~$32/month
create_alb         = false  # Saves ~$16/month
```

## 📊 Expected Monthly Costs

### Scenario 1: Maximum Free Tier (Recommended)
```
├── EC2: 1 x t2.micro               → $0 (free tier)
├── RDS: 1 x db.t3.micro            → $0 (free tier)
├── VPC + Networking                → $0 (free tier)
├── Elastic IP (attached)           → $0 (free tier)
├── NAT Gateway                     → $0 (disabled)
└── Application Load Balancer       → $0 (disabled)
                              TOTAL: $0/month
```

### Scenario 2: With Load Balancer (Optional)
```
├── EC2: 1 x t2.micro               → $0 (free tier)
├── RDS: 1 x db.t3.micro            → $0 (free tier)
├── VPC + Networking                → $0 (free tier)
├── Elastic IP (attached)           → $0 (free tier)
├── NAT Gateway                     → $0 (disabled)
└── Application Load Balancer       → ~$16/month
                              TOTAL: ~$16/month
```

### Scenario 3: Full Production (Not Free Tier)
```
├── EC2: 2 x t2.micro               → $0 (free tier)
├── RDS: 1 x db.t3.micro            → $0 (free tier)
├── VPC + Networking                → $0 (free tier)
├── Elastic IPs                     → $0 (free tier)
├── NAT Gateway                     → ~$32/month
└── Application Load Balancer       → ~$16/month
                              TOTAL: ~$48/month
```

## ⚙️ Configuration Files

### terraform.tfvars (Free Tier Optimized)

```hcl
# AWS Configuration
aws_region = "us-east-1"  # Free tier available in all regions
project_name = "devops-mid"
environment = "production"

# VPC Configuration (FREE)
vpc_cidr             = "10.0.0.0/16"
availability_zones   = ["us-east-1a", "us-east-1b"]
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]

# EC2 Configuration (FREE TIER)
ec2_instance_count = 1           # 1 instance for fully free
ec2_instance_type  = "t2.micro"  # Must be t2.micro for free tier

# RDS Configuration (FREE TIER)
db_instance_class = "db.t3.micro"           # Free tier eligible
db_name          = "devopsdb"
db_username      = "dbadmin"
db_password      = "YourSecurePassword123!" # CHANGE THIS!

# Cost Optimization (SAVE MONEY)
create_nat_gateway = false  # Set true if you need private subnet internet access
create_alb         = false  # Set true if you need load balancing

# Security Configuration
allowed_ssh_cidr = ["YOUR_IP/32"]  # CHANGE THIS to your IP for security
```

## 🔒 Security Best Practices

Even on free tier, maintain security:

1. **Restrict SSH Access**
   ```hcl
   allowed_ssh_cidr = ["YOUR_IP/32"]  # Not 0.0.0.0/0
   ```

2. **Use Strong Passwords**
   ```hcl
   db_password = "SecureP@ssw0rd!2024"  # Min 12 chars
   ```

3. **Keep Software Updated**
   - Ansible playbook handles this automatically
   - Run regularly: `ansible-playbook playbook.yaml --tags update`

4. **Monitor Costs**
   ```bash
   # Check AWS billing dashboard regularly
   aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 \
     --granularity MONTHLY --metrics BlendedCost
   ```

## 🚨 Free Tier Limitations

### Time Limits
- **750 hours/month** for EC2 = 31.25 days
  - 1 instance running 24/7 = OK ✅
  - 2 instances running 24/7 = NOT FREE after 375 hours ❌

### Storage Limits
- **RDS:** 20GB storage max for free tier
- **EC2:** 30GB total EBS storage (General Purpose SSD)

### Data Transfer
- **EC2:** 15GB outbound per month
- **RDS:** 20GB backup storage

### What Happens After Limits
- AWS will charge overage at standard rates
- Set up billing alarms to avoid surprises

## 📊 Monitoring Free Tier Usage

### AWS Console
1. Go to AWS Billing Dashboard
2. Click "Free Tier"
3. View usage by service

### CLI Command
```bash
# Install AWS CLI
aws configure

# Check free tier usage
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics UsageQuantity \
  --group-by Type=DIMENSION,Key=SERVICE

# Set up billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name billing-alarm \
  --alarm-description "Alert when charges exceed $5" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold
```

## 💡 Tips to Stay in Free Tier

### 1. Stop Resources When Not in Use
```bash
# Stop EC2 instances (still uses EBS storage)
aws ec2 stop-instances --instance-ids i-xxxxx

# Stop RDS (creates backup, restarts takes time)
aws rds stop-db-instance --db-instance-identifier devops-mid-postgres
```

### 2. Use Terraform Destroy
```bash
cd infra
terraform destroy  # Removes all resources
```

### 3. Schedule Resources
```bash
# Create Lambda to stop instances at night
# Start instances only during working hours
```

### 4. Monitor Daily
```bash
# Check running instances
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType]'

# Check RDS instances
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus,DBInstanceClass]'
```

## 🎓 Alternative Free Tier Configurations

### Option 1: Single EC2 Only (No RDS)
- Use SQLite on EC2 instead of RDS
- Cost: $0/month
- Good for: Development, testing

### Option 2: EC2 + RDS (Recommended)
- 1 EC2 + 1 RDS instance
- Cost: $0/month (within free tier)
- Good for: Full application testing

### Option 3: Kubernetes Alternative (ECS Fargate)
- AWS ECS with Fargate has free tier too
- 20GB storage, limited compute
- May be complex for this assignment

## ⚠️ Common Billing Mistakes

### ❌ Don't Do This:
1. **Running 3+ t2.micro instances** → Exceeds 750 hours
2. **Leaving NAT Gateway enabled** → ~$32/month
3. **Using t2.small or larger** → Not free tier eligible
4. **Elastic IP without instance** → $0.005/hour charge
5. **Multi-AZ RDS** → Doubles instance hours
6. **gp3 storage** → Use gp2 for free tier
7. **Encrypted RDS** → Not available on free tier

### ✅ Do This:
1. **Use 1-2 t2.micro instances max**
2. **Disable NAT Gateway** (set `create_nat_gateway = false`)
3. **Use db.t3.micro for RDS**
4. **Attach Elastic IPs to running instances**
5. **Single-AZ RDS** (set `multi_az = false`)
6. **Use gp2 storage type**
7. **Disable storage encryption**

## 🔍 Verification Checklist

Before running `terraform apply`, verify:

- [ ] `ec2_instance_type = "t2.micro"`
- [ ] `ec2_instance_count = 1` (or 2 max)
- [ ] `db_instance_class = "db.t3.micro"`
- [ ] `create_nat_gateway = false`
- [ ] `create_alb = false` (unless you need it)
- [ ] `storage_type = "gp2"` (in rds.tf)
- [ ] `storage_encrypted = false` (in rds.tf)
- [ ] `multi_az = false` (in rds.tf)

## 📞 Support

If you see unexpected charges:

1. **Check AWS Billing Dashboard**
   - https://console.aws.amazon.com/billing/

2. **Review Cost Explorer**
   - Group by Service
   - Filter by time period

3. **Contact AWS Support**
   - Free tier support available
   - Chat or email support

4. **Emergency Cost Control**
   ```bash
   # Immediately destroy all resources
   cd infra
   terraform destroy -auto-approve
   ```

## 🎯 Summary

**For completely FREE deployment:**
```hcl
ec2_instance_count = 1
ec2_instance_type  = "t2.micro"
db_instance_class  = "db.t3.micro"
create_nat_gateway = false
create_alb         = false
```

**This configuration will cost:** $0/month within free tier limits

**Free tier expires after:** 12 months from AWS account creation

**Total hours available:** 750 hours/month per service

---

**Always monitor your AWS billing dashboard to ensure you stay within free tier limits!**
