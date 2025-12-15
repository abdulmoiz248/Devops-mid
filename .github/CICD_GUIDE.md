# CI/CD Pipeline Documentation - GitHub Actions

Complete guide for the automated CI/CD pipeline that builds, tests, deploys, and destroys infrastructure.

## 📋 Table of Contents
1. [Pipeline Overview](#pipeline-overview)
2. [Pipeline Stages](#pipeline-stages)
3. [Setup Instructions](#setup-instructions)
4. [Running the Pipeline](#running-the-pipeline)
5. [Screenshots for Assignment](#screenshots-for-assignment)
6. [Troubleshooting](#troubleshooting)

## 🎯 Pipeline Overview

The CI/CD pipeline automates the entire deployment lifecycle:

```
Build & Test → Security Scan → Docker Build → Terraform Provision 
     ↓              ↓              ↓              ↓
   Pass          Pass           Push           Create EC2/RDS
                                                      ↓
                                              Ansible Configure
                                                      ↓
                                              Smoke Tests
                                                      ↓
                                              Terraform Destroy
```

### Workflow Files

- **[.github/workflows/main.yml](.github/workflows/main.yml)** - Main CI/CD pipeline
- **[.github/workflows/destroy.yml](.github/workflows/destroy.yml)** - Manual infrastructure cleanup

## 🔄 Pipeline Stages

### Stage 1: Build & Test (📦)
**Duration:** ~2-3 minutes

**Actions:**
- Checkout code from repository
- Set up Python 3.11
- Install dependencies from requirements.txt
- Run pytest unit tests
- Generate coverage report
- Test database connection

**Success Criteria:**
- All tests pass
- Code coverage > 70%
- No critical failures

### Stage 2: Security & Linting (🔒)
**Duration:** ~2-3 minutes

**Actions:**
- Run Flake8 (code style checker)
- Run Pylint (code quality analyzer)
- Run Bandit (security vulnerability scanner)
- Check dependencies with Safety
- Run Black (code formatter check)
- Run isort (import sorter check)
- Scan Terraform with tfsec

**Success Criteria:**
- No critical security vulnerabilities
- Code style compliant
- No high-severity linting issues

**Tools Used:**
- **Flake8** - PEP 8 style guide
- **Pylint** - Code quality and errors
- **Bandit** - Security issues (SQL injection, hardcoded passwords, etc.)
- **Safety** - Known CVEs in dependencies
- **tfsec** - Terraform security best practices

### Stage 3: Docker Build & Push (🐳)
**Duration:** ~3-5 minutes

**Actions:**
- Set up Docker Buildx
- Login to Docker Hub and GitHub Container Registry
- Extract image metadata (tags, labels)
- Build Docker image with caching
- Push to both registries
- Scan image with Trivy for vulnerabilities

**Success Criteria:**
- Image builds successfully
- Image pushed to registries
- No critical CVEs in image

**Image Tags:**
- `latest` (on main branch)
- `<branch-name>` (branch name)
- `<branch>-<commit-sha>` (unique identifier)

### Stage 4: Terraform Provision (🏗️)
**Duration:** ~10-15 minutes

**Actions:**
- Configure AWS credentials
- Initialize Terraform
- Validate configuration
- Run terraform plan
- Apply infrastructure changes
- Save Terraform state
- Extract outputs (EC2 IPs, RDS endpoint)
- Wait for EC2 to be ready

**Resources Created:**
- VPC with public/private subnets
- 1 EC2 instance (t2.micro)
- RDS PostgreSQL database (db.t3.micro)
- Security groups
- Internet Gateway
- Route tables

**Success Criteria:**
- All resources created successfully
- EC2 instances running
- RDS database available
- Security groups configured

### Stage 5: Ansible Deploy (⚙️)
**Duration:** ~5-10 minutes

**Actions:**
- Install Ansible and collections
- Configure AWS credentials for dynamic inventory
- Set up SSH key
- Generate Ansible inventory from Terraform outputs
- Test connectivity with ansible ping
- Run main playbook
- Verify Docker installation
- Check Docker service status

**Configuration Applied:**
- System updates
- Docker and Docker Compose installation
- Python and dependencies
- Application directory setup
- Environment variables
- Log rotation
- Health check scripts
- PostgreSQL client

**Success Criteria:**
- Ansible connectivity successful
- All playbook tasks pass
- Docker service running
- Application directory created

### Stage 6: Smoke Tests (✅)
**Duration:** ~2-3 minutes

**Actions:**
- Install test dependencies
- Wait for services to stabilize
- Run smoke test script
- Test EC2 connectivity
- Test health endpoints
- Test database connectivity
- Upload test results

**Tests Performed:**
- SSH port accessibility (port 22)
- HTTP health endpoint (port 5000)
- Application status endpoints
- Database port connectivity (port 5432)
- Docker service verification

**Success Criteria:**
- All EC2 instances accessible
- Health endpoints responding
- Database connection successful

### Stage 7: Terraform Destroy (💥)
**Duration:** ~10-12 minutes

**Actions:**
- Download Terraform state
- Wait 2 minutes (for testing/screenshots)
- Run terraform destroy
- Verify all resources deleted
- Check for remaining instances

**Resources Destroyed:**
- EC2 instances
- RDS database
- VPC and subnets
- Security groups
- Internet Gateway
- Elastic IPs

**Success Criteria:**
- All resources terminated
- No billing charges remain
- AWS account clean

### Final Stage: Pipeline Status (📊)

**Actions:**
- Collect results from all stages
- Generate summary report
- Display job statuses
- Link to workflow run

**Report Includes:**
- Status of each stage (success/failure)
- Deployment information
- Commit details
- Triggered by information

## 🚀 Setup Instructions

### 1. Configure GitHub Secrets

Go to **Settings → Secrets and variables → Actions → New repository secret**

Add these secrets:

```plaintext
AWS_ACCESS_KEY_ID         = Your AWS access key
AWS_SECRET_ACCESS_KEY     = Your AWS secret key
DB_PASSWORD               = Strong database password
DOCKER_USERNAME           = Your Docker Hub username
DOCKER_PASSWORD           = Your Docker Hub token
SSH_PRIVATE_KEY           = Your SSH private key (full PEM content)
```

See [SECRETS.md](.github/SECRETS.md) for detailed instructions.

### 2. Prepare Repository

```bash
# Ensure all files are committed
git add .
git commit -m "Add CI/CD pipeline"
git push origin main
```

### 3. Update Configuration

**In `infra/terraform.tfvars.example`:**
```hcl
# Ensure these values match your requirements
create_nat_gateway = false  # Free tier
create_alb         = false  # Free tier
ec2_instance_count = 1      # Free tier
```

**In `.github/workflows/main.yml`:**
- Verify AWS region matches your preference
- Check instance types are free tier eligible

## 🎬 Running the Pipeline

### Automatic Trigger

Pipeline runs automatically on:
- Push to `main` or `master` branch
- Pull request to `main` or `master`

```bash
git add .
git commit -m "Deploy infrastructure"
git push origin main
```

### Manual Trigger

1. Go to **Actions** tab in GitHub
2. Select **Complete CI/CD Pipeline - Deploy & Destroy**
3. Click **Run workflow**
4. Choose options:
   - Skip destroy: Yes/No
   - Deployment mode: full/infrastructure-only/configuration-only
5. Click **Run workflow**

### Monitor Progress

1. Go to **Actions** tab
2. Click on your workflow run
3. Watch real-time logs
4. Download artifacts when complete

## 📸 Screenshots for Assignment

### Screenshot 1: Pipeline Overview
**Location:** Actions tab → Workflow run

**Shows:**
- All 7 stages listed
- Green checkmarks for passed stages
- Total duration

**How to capture:**
1. Wait for pipeline to complete
2. Go to Actions → Latest workflow run
3. Screenshot the full workflow view

### Screenshot 2: Stage Details
**Location:** Actions → Workflow run → Specific job

**Shows:**
- Individual stage with all steps
- Execution time for each step
- Success status

**How to capture:**
1. Click on "Stage 1: Build & Test"
2. Expand all steps
3. Screenshot showing all green checks

### Screenshot 3: Terraform Apply Output
**Location:** Stage 4: Terraform Provision → Terraform Apply step

**Shows:**
- Resources being created
- EC2 instances created
- RDS database created
- Apply complete message

**How to capture:**
1. Click on "Terraform Provision" job
2. Expand "Terraform Apply" step
3. Screenshot showing resource creation

### Screenshot 4: Ansible Playbook Execution
**Location:** Stage 5: Ansible Deploy → Run Ansible Playbook step

**Shows:**
- PLAY RECAP
- Tasks: ok, changed, failed counters
- All green (ok) status

**How to capture:**
1. Click on "Ansible Deploy" job
2. Expand "Run Ansible Playbook" step
3. Scroll to bottom for PLAY RECAP
4. Screenshot showing success

### Screenshot 5: Smoke Test Results
**Location:** Stage 6: Smoke Tests → Run smoke tests step

**Shows:**
- All tests passing
- Health checks successful
- Database connectivity OK

**How to capture:**
1. Click on "Smoke Tests" job
2. Expand "Run smoke tests" step
3. Screenshot showing test results

### Screenshot 6: Terraform Destroy
**Location:** Stage 7: Terraform Destroy → Terraform Destroy step

**Shows:**
- Resources being destroyed
- Destroy complete message
- 0 resources remaining

**How to capture:**
1. Click on "Terraform Destroy" job
2. Expand "Terraform Destroy" step
3. Screenshot showing destruction complete

### Screenshot 7: Final Pipeline Status
**Location:** Actions → Completed workflow

**Shows:**
- All stages completed successfully
- Total execution time
- Artifacts generated

**How to capture:**
1. Return to main workflow view
2. Screenshot showing all stages green
3. Note total duration

### Screenshot 8: Artifacts
**Location:** Bottom of workflow run page

**Shows:**
- test-results
- security-reports
- terraform-outputs
- smoke-test-results

**How to capture:**
1. Scroll to bottom of workflow run
2. Screenshot "Artifacts" section

## 📥 Downloading Artifacts

Pipeline generates several artifacts:

### Available Artifacts

1. **test-results** - Unit test coverage reports
2. **security-reports** - Bandit security scan results
3. **terraform-outputs** - Infrastructure output values
4. **terraform-state** - Terraform state file
5. **smoke-test-results** - Post-deployment test logs

### How to Download

1. Go to completed workflow run
2. Scroll to **Artifacts** section
3. Click artifact name to download
4. Extract ZIP file

### Using Artifacts

**Terraform Outputs:**
```bash
unzip terraform-outputs.zip
cat terraform-output.txt
```

**Test Results:**
```bash
unzip test-results.zip
cat coverage.xml
```

## 🔧 Troubleshooting

### Pipeline Fails at Stage 1 (Build & Test)

**Symptoms:**
- Tests failing
- Import errors

**Solutions:**
```bash
# Run tests locally first
pytest tests/ -v

# Check dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### Pipeline Fails at Stage 2 (Security)

**Symptoms:**
- Linting errors
- Security vulnerabilities found

**Solutions:**
```bash
# Fix linting issues
flake8 app/
black app/
isort app/

# Check for security issues
bandit -r app/
safety check
```

### Pipeline Fails at Stage 3 (Docker Build)

**Symptoms:**
- Docker login failed
- Build errors

**Solutions:**
1. Verify Docker Hub credentials in GitHub secrets
2. Check Dockerfile syntax
3. Test build locally:
   ```bash
   docker build -t test .
   ```

### Pipeline Fails at Stage 4 (Terraform)

**Symptoms:**
- AWS credentials error
- Resource limit exceeded
- Validation errors

**Solutions:**

**AWS Credentials:**
```bash
# Verify credentials work
aws sts get-caller-identity

# Check IAM permissions
aws iam get-user
```

**Resource Limits:**
- Check AWS Free Tier limits
- Verify no existing VPCs blocking
- Ensure region has capacity

**Validation:**
```bash
cd infra
terraform init
terraform validate
terraform plan
```

### Pipeline Fails at Stage 5 (Ansible)

**Symptoms:**
- SSH connection failed
- Permission denied
- Module not found

**Solutions:**

**SSH Connection:**
1. Verify `SSH_PRIVATE_KEY` secret is correctly set
2. Check EC2 security group allows SSH (port 22)
3. Ensure EC2 instances are running

**Permissions:**
```bash
# SSH key should have correct permissions
chmod 600 ~/.ssh/id_rsa
```

**Modules:**
```bash
# Reinstall Ansible collections
ansible-galaxy collection install -r ansible/requirements.yml --force
```

### Pipeline Fails at Stage 6 (Smoke Tests)

**Symptoms:**
- Health check timeout
- Connection refused

**Solutions:**
1. Application may not be deployed yet (this is expected)
2. Check EC2 security group allows port 5000
3. Verify Docker containers are running
4. Allow more time for services to start

### Pipeline Fails at Stage 7 (Destroy)

**Symptoms:**
- Resources still exist
- Deletion errors

**Solutions:**

**Manual Cleanup:**
```bash
cd infra
terraform destroy -auto-approve
```

**Check for stuck resources:**
```bash
# List EC2 instances
aws ec2 describe-instances --filters "Name=tag:Project,Values=devops-mid"

# List RDS instances
aws rds describe-db-instances

# Force delete if needed
aws ec2 terminate-instances --instance-ids i-xxxxx
aws rds delete-db-instance --db-instance-identifier devops-mid-postgres --skip-final-snapshot
```

### Workflow Not Triggering

**Solutions:**
1. Check workflow file syntax (YAML)
2. Verify you pushed to correct branch
3. Check Actions are enabled in repository settings
4. Review workflow triggers in `on:` section

### Secrets Not Working

**Solutions:**
1. Verify secret names match exactly (case-sensitive)
2. Re-add secrets (delete and recreate)
3. Check for trailing spaces in secret values
4. Verify secrets are set in correct repository

## 📊 Pipeline Metrics

### Expected Execution Times

| Stage | Duration | Can Fail |
|-------|----------|----------|
| Build & Test | 2-3 min | Yes |
| Security & Lint | 2-3 min | No (soft fail) |
| Docker Build | 3-5 min | Yes |
| Terraform Provision | 10-15 min | Yes |
| Ansible Deploy | 5-10 min | Yes |
| Smoke Tests | 2-3 min | No (soft fail) |
| Terraform Destroy | 10-12 min | Yes |
| **Total** | **34-51 min** | - |

### Cost Breakdown

With free tier account:
- GitHub Actions: 2000 minutes/month free
- This pipeline: ~45 minutes per run
- Runs available: ~44 per month
- **Cost: $0** (within free tier)

## 🎓 Best Practices

### 1. Branch Protection
Set up branch protection rules:
- Require pull request reviews
- Require status checks to pass
- No force pushes

### 2. Secrets Management
- Rotate secrets every 90 days
- Use least privilege IAM policies
- Never log secret values

### 3. Cost Control
- Always destroy infrastructure when done
- Monitor AWS billing dashboard
- Set up billing alerts

### 4. Testing
- Run tests locally before pushing
- Use pull requests for testing changes
- Review pipeline logs regularly

### 5. Documentation
- Document any custom changes
- Keep README updated
- Log infrastructure changes

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## ✅ Assignment Checklist

For Step 6 - CI/CD Pipeline [10 Marks]:

- [x] Created `.github/workflows/main.yml`
- [x] Created `.github/workflows/destroy.yml`
- [x] Implemented all 7 required stages:
  - [x] Build & Test
  - [x] Security/Linting
  - [x] Docker build and push
  - [x] Terraform apply (infrastructure)
  - [x] Ansible deploy
  - [x] Post-deploy smoke tests
  - [x] Terraform destroy
- [ ] Configure GitHub secrets
- [ ] Push to GitHub to trigger pipeline
- [ ] Capture screenshots of all stages
- [ ] Document pipeline execution
- [ ] Verify infrastructure cleanup

---

**Created for DevOps Mid Assignment - Step 6: CI/CD Pipeline**
