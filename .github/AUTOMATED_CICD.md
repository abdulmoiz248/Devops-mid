# 🚀 Fully Automated CI/CD Pipeline

## Overview
This CI/CD pipeline is **100% automated** - no manual SSH or deployments required. Just push your code and everything happens automatically!

## 🔄 Complete Automation Flow

```
Push Code → Build → Test → Docker Build → Push to Docker Hub → 
Terraform Creates EC2 → Ansible Installs Docker → Ansible Pulls & Runs Container → 
Smoke Tests → Auto Destroy
```

## 📋 Prerequisites

### Required GitHub Secrets

| Secret Name | Description | How to Get |
|------------|-------------|------------|
| `AWS_ACCESS_KEY_ID` | AWS access key | AWS IAM Console |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | AWS IAM Console |
| `DB_PASSWORD` | RDS database password | Choose a strong password |
| `DOCKERHUB_USERNAME` | Docker Hub username | hub.docker.com account |
| `DOCKERHUB_TOKEN` | Docker Hub access token | Docker Hub → Settings → Security |
| `SSH_PRIVATE_KEY` | SSH private key for EC2 | Generate using scripts/generate-cicd-keys.ps1 |
| `SSH_PUBLIC_KEY` | SSH public key for EC2 | Generate using scripts/generate-cicd-keys.ps1 |

### Quick Setup Commands

```powershell
# Generate SSH keys for CI/CD
.\scripts\generate-cicd-keys.ps1

# Add secrets to GitHub (prompts for each value)
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
gh secret set DB_PASSWORD
gh secret set DOCKERHUB_USERNAME
gh secret set DOCKERHUB_TOKEN
```

## 🎯 How It Works

### Stage 1: Build & Test
- ✅ Python dependencies installed
- ✅ Unit tests executed
- ✅ Code quality verified

### Stage 2: Security & Linting
- ✅ Flake8 code linting
- ✅ Bandit security scan
- ✅ Code quality checks

### Stage 3: Docker Build & Push
- ✅ Builds Docker image from Dockerfile
- ✅ Pushes to Docker Hub: `username/devops-mid:latest`
- ✅ Also pushes to GitHub Container Registry (backup)
- ✅ Trivy vulnerability scan

**Key Point**: Image is built and available on Docker Hub before infrastructure is created!

### Stage 4: Terraform Infrastructure
- ✅ Creates VPC, Subnets, Security Groups
- ✅ Launches EC2 instance (t2.micro - free tier)
- ✅ Creates RDS PostgreSQL (db.t3.micro - free tier)
- ✅ Configures security groups to allow access
- ✅ Passes Docker image name to infrastructure

**Automated**: No manual Terraform commands needed!

### Stage 5: Ansible Configuration & Deployment
This is where the magic happens! **Fully automated deployment**:

#### Step 1: Ansible Configures Server
```yaml
- Install Docker
- Install Docker Compose
- Install Python dependencies
- Create application directories
- Configure system settings
```

#### Step 2: Login to Docker Hub
```yaml
- Ansible logs into Docker Hub using secrets
- Credentials: dockerhub_username and dockerhub_token
```

#### Step 3: Pull Docker Image
```yaml
- Pulls your image from Docker Hub
- Image: username/devops-mid:latest
- No need to build on EC2!
```

#### Step 4: Run Container
```yaml
- Stops old container (if exists)
- Starts new container with:
  - Port mapping: 5000:5000
  - Environment variables (DATABASE_URL, etc.)
  - Volume mounts for uploads
  - Health checks
  - Restart policy: always
```

#### Step 5: Verify Deployment
```yaml
- Waits for health check to pass
- Verifies application is running
- Displays access URL
```

**No SSH needed! No manual docker commands!**

### Stage 6: Smoke Tests
- ✅ Tests EC2 instance connectivity
- ✅ Verifies Docker container is running
- ✅ Checks health endpoint
- ✅ Validates application response

### Stage 7: Auto Destroy
- ✅ Automatically destroys all infrastructure
- ✅ Prevents AWS charges
- ✅ Keeps free tier limits safe

## 🐳 Docker Hub Integration

### Why Docker Hub?
1. **Pre-built images**: EC2 just pulls and runs, no building needed
2. **Faster deployments**: Pulling is faster than building
3. **Consistent images**: Same image everywhere
4. **Version control**: Tagged images for rollbacks

### How It's Used in Pipeline

```yaml
# Stage 3: Build and push to Docker Hub
- Docker builds image from source code
- Pushes to Docker Hub as username/devops-mid:latest
- Available for pulling anywhere

# Stage 5: Ansible pulls and runs
- ansible-playbook gets Docker Hub credentials
- Ansible logs into Docker Hub on EC2
- Pulls username/devops-mid:latest
- Runs container with proper configuration
```

### Docker Deployment in Ansible

```yaml
# From playbook.yaml
- name: Login to Docker Hub
  community.docker.docker_login:
    username: "{{ dockerhub_username }}"
    password: "{{ dockerhub_token }}"

- name: Pull Docker image
  community.docker.docker_image:
    name: "{{ docker_image }}"
    source: pull
    state: present

- name: Run application container
  community.docker.docker_container:
    name: devops-mid
    image: "{{ docker_image }}"
    state: started
    restart_policy: always
    ports:
      - "5000:5000"
    env:
      DATABASE_URL: "postgresql://..."
```

## 📊 Variables Passed to Ansible

The pipeline automatically passes these variables:

```yaml
docker_image: username/devops-mid:latest
dockerhub_username: your-username
dockerhub_token: your-token
deploy_app: true
db_host: terraform-output
db_name: terraform-output
db_user: terraform-output
db_password: github-secret
```

## 🔍 How to Verify Everything Works

### 1. Check GitHub Actions
```
Repository → Actions → Latest workflow run
Look for green checkmarks on all stages
```

### 2. Check Docker Hub
```
hub.docker.com → Repositories → devops-mid
Should see latest tag with recent push time
```

### 3. Check EC2 (During Pipeline Run)
```bash
# SSH to EC2 (if you want to verify manually)
ssh -i cicd-keys/cicd_key ec2-user@<ec2-ip>

# Check running containers
docker ps

# Check container logs
docker logs devops-mid

# Test health endpoint
curl http://localhost:5000/health
```

### 4. Check Application
```bash
# From anywhere (during pipeline run)
curl http://<ec2-public-ip>:5000/health
```

## 🎬 Complete Example Run

```bash
# 1. Make a code change
git add .
git commit -m "Update feature"
git push origin main

# 2. GitHub Actions automatically:
#    - Builds code
#    - Runs tests
#    - Builds Docker image
#    - Pushes to Docker Hub ✅
#    - Creates AWS infrastructure with Terraform
#    - Runs Ansible to:
#      * Install Docker on EC2
#      * Login to Docker Hub
#      * Pull username/devops-mid:latest ✅
#      * Run container ✅
#      * Verify health checks ✅
#    - Runs smoke tests
#    - Destroys everything

# 3. You do NOTHING! Just wait for success ✅
```

## 📝 Terraform Variables

The pipeline automatically sets:

```hcl
TF_VAR_db_password         = ${{ secrets.DB_PASSWORD }}
TF_VAR_aws_region          = us-east-1
TF_VAR_docker_image        = username/devops-mid:latest
TF_VAR_ssh_public_key      = ${{ secrets.SSH_PUBLIC_KEY }}
```

## 🔧 Ansible Playbook Variables

Automatically injected:

```yaml
-e "docker_image=username/devops-mid:latest"
-e "dockerhub_username=your-username"
-e "dockerhub_token=your-token"
-e "deploy_app=true"
```

## ✅ Success Criteria

All of these happen automatically:

- [x] Code builds successfully
- [x] Tests pass
- [x] Docker image pushed to Docker Hub
- [x] EC2 instance created
- [x] RDS database created
- [x] Docker installed on EC2 (via Ansible)
- [x] Docker Hub login successful (via Ansible)
- [x] Image pulled from Docker Hub (via Ansible)
- [x] Container running on EC2 (via Ansible)
- [x] Health checks passing
- [x] Infrastructure destroyed

## 🚨 Troubleshooting

### Docker Hub Login Fails
```bash
# Check secrets are set correctly
gh secret list

# Verify Docker Hub token is valid
# Docker Hub → Settings → Security → Access Tokens
```

### Container Not Starting
```bash
# Check Ansible output in GitHub Actions
# Look for "Run application container" step
# Check logs for any error messages
```

### Image Not Found
```bash
# Verify image was pushed to Docker Hub
# Check "Build and push Docker image" step
# Verify dockerhub_username matches image name
```

## 🎯 Key Differences from Manual Deployment

| Manual | Automated CI/CD |
|--------|----------------|
| SSH to server | ✅ No SSH needed |
| git clone repo | ✅ Docker Hub pulls image |
| docker build locally | ✅ Built in CI/CD |
| docker run commands | ✅ Ansible runs it |
| Configure environment | ✅ Auto-configured |
| Start services manually | ✅ Auto-started |
| Manual testing | ✅ Auto smoke tests |
| Remember to cleanup | ✅ Auto destroys |

## 🌟 Benefits

1. **Zero Manual Work**: Push code and walk away
2. **Consistent Deployments**: Same process every time
3. **Fast**: Pre-built images, just pull and run
4. **Secure**: Credentials in secrets, not in code
5. **Testable**: Smoke tests verify everything works
6. **Cost-Safe**: Auto-destroy prevents charges
7. **Rollback Ready**: Tagged images on Docker Hub
8. **Auditable**: Complete logs in GitHub Actions

## 📚 Additional Resources

- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Terraform Variables](https://www.terraform.io/docs/language/values/variables.html)
- [Ansible Docker Modules](https://docs.ansible.com/ansible/latest/collections/community/docker/)

## 🎓 Learning Points

1. **CI/CD automates EVERYTHING** - that's the whole point!
2. **Docker Hub stores images** - EC2 just pulls and runs
3. **Ansible handles deployment** - login, pull, run container
4. **Secrets management** - GitHub secrets passed to tools
5. **Infrastructure as Code** - reproducible, version-controlled

---

**No manual SSH. No manual Docker commands. Just push and deploy! 🚀**
