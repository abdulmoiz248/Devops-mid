# GitHub Actions Secrets Configuration

This document lists all required secrets for the CI/CD pipeline.

## Required Secrets

Configure these secrets in your GitHub repository:
**Settings → Secrets and variables → Actions → New repository secret**

### AWS Credentials

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

**How to get AWS credentials:**
1. Log in to AWS Console
2. Go to IAM → Users → Your User
3. Security credentials → Create access key
4. Choose "Application running outside AWS"
5. Copy Access Key ID and Secret Access Key

### Database Credentials

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DB_PASSWORD` | RDS PostgreSQL password | `SecureP@ssw0rd123!` |

**Requirements:**
- Minimum 8 characters
- Include uppercase, lowercase, numbers, and special characters

### Docker Hub Credentials

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `DOCKER_USERNAME` | Docker Hub username | `yourusername` |
| `DOCKER_PASSWORD` | Docker Hub password or access token | `dckr_pat_xxxxxxxxxxxxx` |

**How to get Docker credentials:**
1. Create account at https://hub.docker.com
2. Go to Account Settings → Security → New Access Token
3. Use token as DOCKER_PASSWORD

### SSH Key

| Secret Name | Description | Format |
|-------------|-------------|--------|
| `SSH_PRIVATE_KEY` | Private SSH key for EC2 access | PEM format (full content) |

**How to add SSH key:**
1. Generate key if you don't have one:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
   ```
2. Copy the ENTIRE private key content:
   ```bash
   cat ~/.ssh/id_rsa
   ```
3. Paste into GitHub secret (include `-----BEGIN` and `-----END` lines)

## Secret Configuration Commands

```bash
# Using GitHub CLI (gh)
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
gh secret set DB_PASSWORD
gh secret set DOCKER_USERNAME
gh secret set DOCKER_PASSWORD
gh secret set SSH_PRIVATE_KEY < ~/.ssh/id_rsa
```

## Environment Variables

These are set in the workflow file and don't need to be configured:

- `PYTHON_VERSION: '3.11'`
- `TERRAFORM_VERSION: '1.6.0'`
- `ANSIBLE_VERSION: '2.14.0'`
- `AWS_REGION: 'us-east-1'`
- `PROJECT_NAME: 'devops-mid'`

## Verifying Secrets

After adding secrets, verify they're set:
1. Go to repository Settings → Secrets and variables → Actions
2. You should see all secrets listed (values are hidden)
3. Test by running the workflow

## Security Best Practices

### ✅ DO:
- Use strong, unique passwords for all services
- Rotate credentials regularly (every 90 days)
- Use access tokens instead of passwords where possible
- Limit AWS IAM permissions to only what's needed
- Enable MFA on AWS account

### ❌ DON'T:
- Never commit secrets to Git
- Don't share secrets in chat/email
- Don't use same password across services
- Don't give secrets overly broad permissions

## AWS IAM Permissions Required

Your AWS Access Key needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "rds:*",
        "vpc:*",
        "elasticloadbalancing:*",
        "iam:GetRole",
        "iam:PassRole"
      ],
      "Resource": "*"
    }
  ]
}
```

**Recommended:** Create a dedicated IAM user for CI/CD with only necessary permissions.

## Troubleshooting

### Error: "No AWS credentials found"
- Check that `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set
- Verify credentials are valid: `aws sts get-caller-identity`

### Error: "Authentication failed" (Docker)
- Verify Docker Hub credentials are correct
- Use access token instead of password
- Check username is exact (case-sensitive)

### Error: "Permission denied (publickey)"
- Verify SSH_PRIVATE_KEY secret contains the full private key
- Check that public key is added to EC2 instances (via Terraform)
- Ensure key format is correct (PEM)

### Error: "Database password does not meet requirements"
- Password must be 8+ characters
- Include uppercase, lowercase, numbers, special chars
- Avoid characters that need escaping in shell: `$`, `` ` ``, `\`

## Testing Secrets Locally

Test your secrets work before adding to GitHub:

```bash
# Test AWS credentials
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
aws sts get-caller-identity

# Test Docker login
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Test SSH key
ssh -i ~/.ssh/id_rsa ec2-user@test-ip

# Test Terraform with DB password
cd infra
terraform plan -var="db_password=YourPassword123!"
```

## Secret Rotation

Rotate secrets every 90 days or immediately if compromised:

1. **AWS Credentials:**
   - Create new access key in AWS Console
   - Update GitHub secret
   - Deactivate old key
   - Delete old key after confirming new one works

2. **Docker Token:**
   - Generate new access token
   - Update GitHub secret
   - Revoke old token

3. **SSH Key:**
   - Generate new key pair
   - Update Terraform configuration
   - Update GitHub secret
   - Remove old public key from EC2

4. **DB Password:**
   - Change password in RDS Console
   - Update GitHub secret
   - Update terraform.tfvars (if stored there)

## Audit Log

Keep track of when secrets were last rotated:

| Secret | Created | Last Rotated | Next Rotation |
|--------|---------|--------------|---------------|
| AWS_ACCESS_KEY_ID | YYYY-MM-DD | YYYY-MM-DD | YYYY-MM-DD |
| DOCKER_PASSWORD | YYYY-MM-DD | YYYY-MM-DD | YYYY-MM-DD |
| SSH_PRIVATE_KEY | YYYY-MM-DD | YYYY-MM-DD | YYYY-MM-DD |
| DB_PASSWORD | YYYY-MM-DD | YYYY-MM-DD | YYYY-MM-DD |

---

**Important:** Never commit this file with actual secret values. Keep this as documentation only.
