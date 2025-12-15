# Generate SSH Keys for CI/CD Pipeline
# PowerShell version for Windows users

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "  SSH Key Generator for GitHub Actions CI/CD Pipeline" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Define key path
$KeyDir = ".\cicd-keys"
$KeyPath = "$KeyDir\github-actions-key"

# Create directory
if (-not (Test-Path $KeyDir)) {
    New-Item -ItemType Directory -Path $KeyDir | Out-Null
}

# Generate SSH key pair
Write-Host "Generating SSH key pair..." -ForegroundColor Green
ssh-keygen -t rsa -b 4096 -f $KeyPath -N '""' -C "github-actions-cicd"

Write-Host ""
Write-Host "SSH keys generated successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "  NEXT STEPS:" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Add these secrets to your GitHub repository:" -ForegroundColor Yellow
Write-Host "   (Settings -> Secrets and variables -> Actions -> New secret)" -ForegroundColor White
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Display private key
Write-Host "SSH_PRIVATE_KEY (copy entire output below):" -ForegroundColor Magenta
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Get-Content $KeyPath | ForEach-Object { Write-Host $_ -ForegroundColor White }
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Copy private key to clipboard
Get-Content $KeyPath -Raw | Set-Clipboard
Write-Host "Private key copied to clipboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Press Enter to continue (will show public key next)..."
Read-Host

# Display public key
Write-Host "SSH_PUBLIC_KEY (copy entire output below):" -ForegroundColor Magenta
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Get-Content "$KeyPath.pub" | ForEach-Object { Write-Host $_ -ForegroundColor White }
Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

# Copy public key to clipboard
Get-Content "$KeyPath.pub" -Raw | Set-Clipboard
Write-Host "Public key copied to clipboard!" -ForegroundColor Green
Write-Host ""

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Adding keys to GitHub Secrets:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Step 1: Go to your GitHub repository" -ForegroundColor White
Write-Host "   Step 2: Click Settings -> Secrets and variables -> Actions" -ForegroundColor White
Write-Host "   Step 3: Click 'New repository secret'" -ForegroundColor White
Write-Host "   Step 4: Add SSH_PRIVATE_KEY (paste from clipboard)" -ForegroundColor White
Write-Host "   Step 5: Add SSH_PUBLIC_KEY (will be copied next)" -ForegroundColor White
Write-Host "   Step 6: Add AWS credentials and other secrets" -ForegroundColor White
Write-Host ""
Write-Host "   Delete keys after adding to GitHub Secrets (optional)" -ForegroundColor Yellow
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Test your setup:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   cd infra" -ForegroundColor White
Write-Host '   $pubKey = Get-Content ..\cicd-keys\github-actions-key.pub -Raw' -ForegroundColor White
Write-Host '   terraform plan -var="ssh_public_key=$pubKey"' -ForegroundColor White
Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Setup complete! Now add the secrets to GitHub and run the pipeline." -ForegroundColor Green
Write-Host ""

# Create a summary file
$SummaryFile = "$KeyDir\GITHUB_SECRETS_SUMMARY.txt"

# Use regular string instead of here-string
$Summary = "GitHub Secrets Configuration Summary`n"
$Summary += "Generated: $(Get-Date)`n`n"
$Summary += "Add these secrets to your GitHub repository:`n"
$Summary += "Settings -> Secrets and variables -> Actions -> New repository secret`n`n"
$Summary += "Required Secrets:`n"
$Summary += "===============================================================`n`n"
$Summary += "1. SSH_PRIVATE_KEY`n"
$Summary += "   Content: See private key in github-actions-key file`n"
$Summary += "   Format: Full content including BEGIN/END lines`n`n"
$Summary += "2. SSH_PUBLIC_KEY`n"
$Summary += "   Content: See public key in github-actions-key.pub file`n"
$Summary += "   Format: Single line starting with ssh-rsa`n`n"
$Summary += "3. AWS_ACCESS_KEY_ID`n"
$Summary += "   Content: Your AWS access key ID`n"
$Summary += "   Get from: AWS Console -> IAM -> Security credentials`n`n"
$Summary += "4. AWS_SECRET_ACCESS_KEY`n"
$Summary += "   Content: Your AWS secret access key`n"
$Summary += "   Get from: AWS Console -> IAM -> Security credentials`n`n"
$Summary += "5. DB_PASSWORD`n"
$Summary += "   Content: A strong password for RDS`n"
$Summary += "   Example: SecurePassword123!`n`n"
$Summary += "6. DOCKERHUB_USERNAME`n"
$Summary += "   Content: Your Docker Hub username`n`n"
$Summary += "7. DOCKERHUB_TOKEN`n"
$Summary += "   Content: Docker Hub access token`n"
$Summary += "   Get from: hub.docker.com -> Settings -> Security -> New Access Token`n`n"
$Summary += "===============================================================`n`n"
$Summary += "After adding all secrets, push your code to GitHub:`n`n"
$Summary += "   git add .`n"
$Summary += "   git commit -m 'Add CI/CD pipeline'`n"
$Summary += "   git push origin main`n`n"
$Summary += "The pipeline will automatically run!`n`n"
$Summary += "===============================================================`n"

$Summary | Out-File -FilePath $SummaryFile -Encoding UTF8

Write-Host "Summary saved to: $SummaryFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Keys are in: $KeyDir" -ForegroundColor Cyan
Write-Host ""
