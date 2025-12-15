# GitHub Actions CI/CD Pipeline Setup Guide

## 🎯 Overview

This guide explains how to set up the complete CI/CD pipeline with proper SSH key configuration for automated deployment to AWS.

## 🔑 SSH Key Solution

**The Problem:** Terraform creates SSH keys at runtime, but GitHub Actions needs them beforehand.

**The Solution:** Generate SSH keys locally and store them as GitHub Secrets, then pass them to both Terraform and Ansible.

## 📋 Prerequisites

1. GitHub repository for your project
2. AWS Account with credentials
3. Docker Hub account
4. Local machine with SSH tools

## 🔧 Step-by-Step Setup

### Step 1: Generate SSH Key Pair

Generate a dedicated SSH key pair for CI/CD (don't use your personal keys):

```bash
# Generate new SSH key pair
ssh-keygen -t rsa -b 4096 -f ./cicd-key -N ""

# This creates:
# - cicd-key (private key)
# - cicd-key.pub (public key)
```

**Important:** Never commit these keys to your repository!

### Step 2: Configure GitHub Secrets

Navigate to your GitHub repository:
**Settings → Secrets and variables → Actions → New repository secret**

Add the following secrets:

#### AWS Credentials

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | AWS Console → IAM → Security credentials |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret key | AWS Console → IAM → Security credentials |
| `AWS_REGION` | `us-east-1` | Or your preferred region |

#### Database

| Secret Name | Value | Example |
|-------------|-------|---------|
| `DB_PASSWORD` | Strong password | `SecurePassword123!` |

#### Docker Hub

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | docker.com account |
| `DOCKERHUB_TOKEN` | Docker Hub access token | Settings → Security → New Access Token |

#### SSH Keys (CRITICAL - Fixed Solution!)

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `SSH_PRIVATE_KEY` | Content of `cicd-key` file | `cat cicd-key` (entire content) |
| `SSH_PUBLIC_KEY` | Content of `cicd-key.pub` file | `cat cicd-key.pub` |

**How to add SSH keys:**

```bash
# On Linux/macOS:
cat cicd-key | pbcopy  # Copies to clipboard (macOS)
cat cicd-key | xclip -selection clipboard  # Copies to clipboard (Linux)

# On Windows (PowerShell):
Get-Content cicd-key | Set-Clipboard

# Then paste into GitHub secret
```

**Format for SSH_PRIVATE_KEY:**
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
(entire key content)
...
-----END RSA PRIVATE KEY-----
```

**Format for SSH_PUBLIC_KEY:**
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@host
```

### Step 3: Verify Terraform Configuration

The Terraform configuration has been updated to accept SSH public key from environment:

**infra/variables.tf:**
```hcl
variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  default     = ""
}
```

**infra/ec2.tf:**
```hcl
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key != "" ? var.ssh_public_key : file(pathexpand("~/.ssh/id_rsa.pub"))
}
```

This means:
- ✅ In CI/CD: Uses `SSH_PUBLIC_KEY` secret
- ✅ Locally: Uses your `~/.ssh/id_rsa.pub`

### Step 4: Test Locally (Optional but Recommended)

Before pushing to GitHub, test locally:

```bash
# Test Terraform with your SSH key
cd infra
terraform init
terraform plan -var="ssh_public_key=$(cat ../cicd-key.pub)" -var="db_password=TestPass123!"

# Don't apply yet! Just verify the plan works
```

### Step 5: Push and Trigger Pipeline

```bash
git add .
git commit -m "Add CI/CD pipeline with proper SSH configuration"
git push origin main
```

The pipeline will automatically:
1. Build and test your application
2. Run security scans
3. Build and push Docker image
4. Provision AWS infrastructure (EC2, RDS, VPC)
5. Configure servers with Ansible
6. Run smoke tests
7. **Destroy all infrastructure** (to avoid costs)

### Step 6: Monitor Pipeline

Watch the pipeline execution:
**GitHub → Actions tab → Select your workflow run**

Each stage should show:
- ✅ Build & Test
- ✅ Security & Linting  
- ✅ Docker Build & Push
- ✅ Terraform Infrastructure
- ✅ Ansible Deploy
- ✅ Smoke Tests
- ✅ Cleanup Infrastructure

## 📸 Taking Screenshots for Assignment

### 1. GitHub Secrets Configuration
Screenshot: Settings → Secrets showing all configured secrets (values hidden)

### 2. Pipeline Overview
Screenshot: Actions tab showing successful workflow run with all stages green

### 3. Individual Stage Details
Screenshots of each stage:
- Build & Test output
- Security scan results
- Docker build logs
- Terraform apply output
- Ansible playbook execution
- Smoke test results
- Terraform destroy output

### 4. AWS Console (Before Destroy)
- Navigate to AWS Console between Stage 6 and Stage 7
- Take screenshots of:
  - EC2 instances running
  - RDS database
  - VPC and subnets
  - Security groups

### 5. AWS Console (After Destroy)
Screenshot: AWS Console showing resources have been cleaned up

## 🔍 Workflow Details

### Pipeline Stages

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Flow                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. Build & Test                                           │
│     ├── Install Python dependencies                        │
│     ├── Run pytest with PostgreSQL                         │
│     └── Generate coverage report                           │
│                                                             │
│  2. Security & Linting                                     │
│     ├── Flake8 linting                                     │
│     ├── Bandit security scan                               │
│     └── Dependency vulnerability check                     │
│                                                             │
│  3. Docker Build & Push                                    │
│     ├── Build multi-stage Docker image                     │
│     ├── Tag with commit SHA                                │
│     └── Push to Docker Hub                                 │
│                                                             │
│  4. Terraform Infrastructure                               │
│     ├── Initialize Terraform                               │
│     ├── Validate configuration                             │
│     ├── Plan infrastructure changes                        │
│     ├── Apply infrastructure (EC2, RDS, VPC)              │
│     └── Export outputs (IPs, endpoints)                    │
│                                                             │
│  5. Ansible Deployment                                     │
│     ├── Generate dynamic inventory from Terraform          │
│     ├── Wait for EC2 to be ready                          │
│     ├── Run playbook (install Docker, configure app)       │
│     └── Verify configuration                               │
│                                                             │
│  6. Smoke Tests                                            │
│     ├── Test EC2 accessibility                            │
│     ├── Verify SSH connection                             │
│     ├── Check Docker installation                         │
│     └── Test application health endpoint                   │
│                                                             │
│  7. Infrastructure Cleanup                                 │
│     ├── Wait 2 minutes (manual inspection window)          │
│     ├── Run terraform destroy                              │
│     ├── Verify all resources deleted                       │
│     └── Confirm no ongoing costs                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Features

✅ **Fully Automated**: No manual intervention required
✅ **Cost-Optimized**: Destroys infrastructure automatically
✅ **Secure**: Uses GitHub Secrets for sensitive data
✅ **Comprehensive**: Tests, builds, deploys, and verifies
✅ **Free Tier**: Configured for AWS free tier resources
✅ **Idempotent**: Can be run multiple times safely

## 🛠️ Customization Options

### Skip Infrastructure Destroy

To keep infrastructure running after deployment:

```yaml
# Manual trigger with option
workflow_dispatch:
  inputs:
    skip_destroy:
      description: 'Skip infrastructure destroy at the end'
      required: false
      type: boolean
      default: false
```

Then trigger manually and set `skip_destroy: true`

### Deploy to Multiple Environments

Add environment-specific secrets:

```
# Production
AWS_ACCESS_KEY_ID_PROD
AWS_SECRET_ACCESS_KEY_PROD
DB_PASSWORD_PROD

# Staging
AWS_ACCESS_KEY_ID_STAGING
AWS_SECRET_ACCESS_KEY_STAGING
DB_PASSWORD_STAGING
```

### Change Destroy Wait Time

Edit the cleanup stage:

```yaml
- name: Wait before destroying
  run: |
    echo "⏳ Waiting 5 minutes..."
    sleep 300  # Change from 120 to 300 seconds
```

## 🔧 Troubleshooting

### Issue: "Permission denied (publickey)" during Ansible

**Cause:** SSH private key not properly configured

**Solution:**
```bash
# Verify your SSH private key format
cat cicd-key
# Should start with: -----BEGIN RSA PRIVATE KEY-----

# Re-copy to GitHub secret ensuring entire content is copied
cat cicd-key | pbcopy

# Paste into GitHub secret WITHOUT any modifications
```

### Issue: Terraform fails with "InvalidKeyPair.NotFound"

**Cause:** SSH public key not passed correctly

**Solution:** Verify `SSH_PUBLIC_KEY` secret contains:
```
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... (one line, no line breaks)
```

### Issue: "Error: UnauthorizedOperation" in Terraform

**Cause:** AWS credentials don't have sufficient permissions

**Solution:** Ensure your IAM user has policies:
- AmazonEC2FullAccess
- AmazonRDSFullAccess
- AmazonVPCFullAccess

### Issue: Ansible playbook times out

**Cause:** EC2 instance not ready yet

**Solution:** The workflow already includes a 30-attempt wait loop. If still failing:
```yaml
# Increase attempts in the workflow
for i in {1..60}; do  # Changed from 30 to 60
```

### Issue: Docker Hub push fails

**Cause:** Invalid Docker Hub credentials

**Solution:**
1. Generate new access token at hub.docker.com
2. Update `DOCKERHUB_TOKEN` secret
3. Ensure `DOCKERHUB_USERNAME` is lowercase

## 📊 Cost Estimates

### Running the Pipeline

**Per successful run:**
- EC2 t2.micro: ~$0.01 (runs ~15 minutes)
- RDS db.t3.micro: ~$0.02 (runs ~15 minutes)
- Data transfer: ~$0.01
- **Total: ~$0.04 per run**

**With destroy enabled:** Costs are minimal as resources only exist 10-15 minutes

**Without destroy:** ~$48/month if left running 24/7

### GitHub Actions Minutes

**Free tier:** 2,000 minutes/month for public repos

**This pipeline uses:**
- ~15-20 minutes per run
- Can run ~100 times/month on free tier

## 🎓 Best Practices

### 1. Secrets Management
- ✅ Use GitHub Secrets for all sensitive data
- ✅ Never commit credentials to repository
- ✅ Rotate keys regularly
- ✅ Use different keys for different environments

### 2. Infrastructure
- ✅ Always destroy after testing
- ✅ Use free tier eligible resources
- ✅ Monitor AWS billing
- ✅ Set up billing alerts

### 3. Pipeline
- ✅ Run on pull requests (without deploy)
- ✅ Deploy only from main branch
- ✅ Use semantic versioning for Docker tags
- ✅ Keep pipeline runs under 30 minutes

### 4. Security
- ✅ Run security scans on every commit
- ✅ Keep dependencies updated
- ✅ Use least privilege IAM policies
- ✅ Enable MFA on AWS account

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Hub](https://hub.docker.com/)
- [AWS Free Tier](https://aws.amazon.com/free/)

## ✅ Pre-Flight Checklist

Before running the pipeline, ensure:

- [ ] All GitHub secrets configured
- [ ] SSH key pair generated (cicd-key, cicd-key.pub)
- [ ] SSH_PRIVATE_KEY secret contains full private key
- [ ] SSH_PUBLIC_KEY secret contains full public key
- [ ] AWS credentials have required permissions
- [ ] Docker Hub account created and credentials added
- [ ] Repository is public or has GitHub Actions enabled
- [ ] Workflow file is in `.github/workflows/` directory
- [ ] Terraform files are in `infra/` directory
- [ ] Ansible files are in `ansible/` directory

## 🎯 Success Criteria

Your pipeline is successful when:

1. ✅ All 7 stages pass with green checkmarks
2. ✅ Docker image appears in Docker Hub
3. ✅ AWS resources are created (visible in console)
4. ✅ Ansible successfully configures EC2
5. ✅ Smoke tests pass
6. ✅ Infrastructure is destroyed
7. ✅ No AWS resources left running

## 📞 Support

If you encounter issues:

1. Check GitHub Actions logs for specific error messages
2. Verify all secrets are correctly configured
3. Test Terraform and Ansible locally first
4. Review AWS CloudWatch logs
5. Check security group rules
6. Ensure billing is under limits

---

**Now your CI/CD pipeline has proper SSH key management! 🎉**

The keys are generated once, stored as secrets, and reused by both Terraform (for creating EC2 access) and Ansible (for configuring servers).
