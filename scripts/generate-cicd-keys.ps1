# Generate SSH Keys for CI/CD Pipeline
# PowerShell version for Windows users

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  SSH Key Generator for GitHub Actions CI/CD Pipeline" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Define key path
$KeyDir = ".\cicd-keys"
$KeyPath = "$KeyDir\github-actions-key"

# Create directory
if (-not (Test-Path $KeyDir)) {
    New-Item -ItemType Directory -Path $KeyDir | Out-Null
}

# Generate SSH key pair
Write-Host "📝 Generating SSH key pair..." -ForegroundColor Green
ssh-keygen -t rsa -b 4096 -f $KeyPath -N '""' -C "github-actions-cicd"

Write-Host ""
Write-Host "✅ SSH keys generated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "1️⃣  Add these secrets to your GitHub repository:" -ForegroundColor Yellow
Write-Host "   (Settings → Secrets and variables → Actions → New secret)" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Display private key
Write-Host "🔑 SSH_PRIVATE_KEY (copy entire output below):" -ForegroundColor Magenta
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Get-Content $KeyPath | ForEach-Object { Write-Host $_ -ForegroundColor White }
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Copy private key to clipboard
Get-Content $KeyPath -Raw | Set-Clipboard
Write-Host "✅ Private key copied to clipboard!" -ForegroundColor Green
Write-Host ""

# Display public key
Write-Host "🔓 SSH_PUBLIC_KEY (copy entire output below):" -ForegroundColor Magenta
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Get-Content "$KeyPath.pub" | ForEach-Object { Write-Host $_ -ForegroundColor White }
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "2️⃣  Adding keys to GitHub Secrets:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Step 1: Go to your GitHub repository" -ForegroundColor White
Write-Host "   Step 2: Click Settings → Secrets and variables → Actions" -ForegroundColor White
Write-Host "   Step 3: Click 'New repository secret'" -ForegroundColor White
Write-Host ""
Write-Host "   For SSH_PRIVATE_KEY:" -ForegroundColor Cyan
Write-Host "   ✅ Private key is already in your clipboard!" -ForegroundColor Green
Write-Host "   Just paste (Ctrl+V) into the GitHub secret value" -ForegroundColor White
Write-Host ""
Write-Host "   For SSH_PUBLIC_KEY:" -ForegroundColor Cyan
Get-Content "$KeyPath.pub" -Raw | Set-Clipboard
Write-Host "   ✅ Public key is now in your clipboard!" -ForegroundColor Green
Write-Host "   Paste (Ctrl+V) into the GitHub secret value" -ForegroundColor White
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  IMPORTANT SECURITY NOTES:" -ForegroundColor Red
Write-Host ""
Write-Host "   • Keys are stored in: cicd-keys\" -ForegroundColor Yellow
Write-Host "   • This directory is in .gitignore" -ForegroundColor Yellow
Write-Host "   • NEVER commit these keys to git" -ForegroundColor Red
Write-Host "   • Keep the private key secure" -ForegroundColor Yellow
Write-Host "   • Delete keys after adding to GitHub Secrets (optional)" -ForegroundColor Yellow
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "3️⃣  Test your setup:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   cd infra" -ForegroundColor White
Write-Host '   $pubKey = Get-Content ..\cicd-keys\github-actions-key.pub -Raw' -ForegroundColor White
Write-Host '   terraform plan -var="ssh_public_key=$pubKey"' -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "✨ Setup complete! Now add the secrets to GitHub and run the pipeline." -ForegroundColor Green
Write-Host ""

# Create a summary file
$SummaryFile = "$KeyDir\GITHUB_SECRETS_SUMMARY.txt"
$SummaryContent = @"
GitHub Secrets Configuration Summary
Generated: $(Get-Date)

Add these secrets to your GitHub repository:
Settings -> Secrets and variables -> Actions -> New repository secret

Required Secrets:
===============================================================

1. SSH_PRIVATE_KEY
   Content: See private key in github-actions-key file
   Format: Full content including BEGIN/END lines

2. SSH_PUBLIC_KEY  
   Content: See public key in github-actions-key.pub file
   Format: Single line starting with ssh-rsa

3. AWS_ACCESS_KEY_ID
   Content: Your AWS access key ID
   Get from: AWS Console -> IAM -> Security credentials

4. AWS_SECRET_ACCESS_KEY
   Content: Your AWS secret access key
   Get from: AWS Console -> IAM -> Security credentials

5. AWS_REGION
   Content: us-east-1 (or your preferred region)

6. DB_PASSWORD
   Content: A strong password for RDS
   Example: SecurePassword123!

7. DOCKERHUB_USERNAME
   Content: Your Docker Hub username

8. DOCKERHUB_TOKEN
   Content: Docker Hub access token
   Get from: hub.docker.com -> Settings -> Security -> New Access Token

===============================================================

After adding all secrets, push your code to GitHub:

   git add .
   git commit -m "Add CI/CD pipeline"
   git push origin main

The pipeline will automatically run!

===============================================================
"@

$SummaryContent | Out-File -FilePath $SummaryFile -Encoding UTF8

Write-Host "Summary saved to: $SummaryFile" -ForegroundColor Cyan
Write-Host ""
