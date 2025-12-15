# 🎯 Quick Reference: CI/CD Automation

## One-Time Setup (5 minutes)

### Step 1: Generate SSH Keys
```powershell
.\scripts\generate-cicd-keys.ps1
```
This creates SSH keys and copies them to clipboard automatically.

### Step 2: Add GitHub Secrets
Go to: **Your Repo → Settings → Secrets and variables → Actions → New repository secret**

Add these 7 secrets:

| Secret Name | Value | Notes |
|------------|-------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key | From AWS IAM |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret | From AWS IAM |
| `DB_PASSWORD` | Strong password | Choose any strong password |
| `DOCKERHUB_USERNAME` | Docker Hub username | hub.docker.com account |
| `DOCKERHUB_TOKEN` | Docker Hub token | Settings → Security → New Access Token |
| `SSH_PRIVATE_KEY` | From script output | Copied to clipboard by script |
| `SSH_PUBLIC_KEY` | From script output | Copied to clipboard by script |

### Step 3: Done! 
Push code and watch the magic ✨

## Daily Usage

```bash
# Make changes
vim app/routes/products_routes.py

# Commit and push
git add .
git commit -m "Add new feature"
git push origin main

# ✅ DONE! Everything else is automatic
```

## What Happens Automatically

| Stage | What It Does | Time |
|-------|-------------|------|
| 1️⃣ Build & Test | Installs dependencies, runs tests | ~2 min |
| 2️⃣ Security | Linting, security scans | ~1 min |
| 3️⃣ **Docker Build** | **Builds image, pushes to Docker Hub** | ~3 min |
| 4️⃣ Terraform | Creates EC2, RDS, VPC on AWS | ~5 min |
| 5️⃣ **Ansible** | **Installs Docker, pulls image, runs container** | ~3 min |
| 6️⃣ Tests | Health checks, smoke tests | ~1 min |
| 7️⃣ Destroy | Deletes all AWS resources | ~2 min |
| **Total** | | **~17 min** |

## The Docker Hub Workflow

```
┌──────────────┐
│ Your Code    │
└──────┬───────┘
       │
       ▼
┌──────────────────────────┐
│ GitHub Actions           │
│ - docker build           │
│ - docker push            │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Docker Hub               │
│ username/devops-mid      │
│ :latest                  │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Terraform                │
│ - Creates EC2            │
└──────┬───────────────────┘
       │
       ▼
┌──────────────────────────┐
│ Ansible on EC2           │
│ - Install Docker         │
│ - docker login           │
│ - docker pull ⬅          │
│ - docker run             │
└──────────────────────────┘
       │
       ▼
   🎉 Running!
```

## Checking Status

### GitHub Actions
```
Repo → Actions tab → Latest workflow
Look for ✅ on all stages
```

### Docker Hub
```
hub.docker.com → Repositories → devops-mid
Should see "latest" tag with recent timestamp
```

### Logs (Optional)
Click on any stage in GitHub Actions to see detailed logs:
- **Stage 3**: See Docker build output
- **Stage 5**: See Ansible pulling and running container
- **Stage 6**: See health check results

## Common Variables

These are automatically set by the pipeline:

```yaml
# Passed to Terraform
docker_image: username/devops-mid:latest
ssh_public_key: <from secrets>
db_password: <from secrets>

# Passed to Ansible
docker_image: username/devops-mid:latest
dockerhub_username: <from secrets>
dockerhub_token: <from secrets>
deploy_app: true
```

## No Manual Work!

❌ Things you DON'T do:
- SSH to server
- Run docker build
- Run docker push
- Run terraform apply
- Run ansible-playbook
- Configure servers
- Install dependencies
- Start containers
- Run tests manually
- Clean up resources

✅ Things you DO:
- Push code to GitHub
- Check Actions tab
- See green checkmarks
- Celebrate! 🎉

## Troubleshooting Quick Fixes

### "Docker Hub login failed"
```bash
# Regenerate Docker Hub token
1. hub.docker.com → Settings → Security
2. Generate New Access Token
3. Copy token
4. GitHub → Settings → Secrets → DOCKERHUB_TOKEN → Update
```

### "Terraform apply failed"
```bash
# Check AWS credentials
gh secret list  # Should show AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
```

### "Ansible failed"
```bash
# Check SSH keys
gh secret list  # Should show SSH_PRIVATE_KEY, SSH_PUBLIC_KEY
# Re-run: .\scripts\generate-cicd-keys.ps1
```

## Files to Know

| File | What It Does |
|------|-------------|
| `.github/workflows/main.yml` | **Main pipeline** - runs everything |
| `ansible/playbook.yaml` | Ansible automation - **pulls & runs Docker** |
| `infra/*.tf` | Terraform - creates AWS resources |
| `Dockerfile` | Defines your app image |

## Success Indicators

✅ **In GitHub Actions:**
- All 7 stages green
- "Deploy Application" step succeeds
- Smoke tests pass
- Resources destroyed

✅ **In Docker Hub:**
- Repository exists: `username/devops-mid`
- Tag `latest` updated recently
- Image size reasonable (~500MB)

✅ **In Logs:**
- "Docker image pulled successfully"
- "Container started"
- "Health check: PASSED"
- "Application deployed successfully!"

## Key Insight

**The entire point of CI/CD is automation!**

- You write code
- Pipeline handles EVERYTHING else
- No manual deployment steps
- No SSH sessions
- No manual docker commands
- Just push and trust the automation! 🚀

## Remember

**Docker Hub = Your Image Registry**
- CI/CD pushes images there
- Ansible pulls images from there
- EC2 runs what was pulled
- No building on EC2 itself!

**Ansible = Your Deployment Bot**
- Installs Docker
- Logs into Docker Hub
- Pulls your image
- Runs your container
- All automatically!

---

**Total manual work required: `git push` ← That's it!** 🎯
