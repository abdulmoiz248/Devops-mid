# PowerShell Quick Deploy Script
# Run this script to deploy the entire infrastructure

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DevOps Mid - Quick Deploy Script" -ForegroundColor Cyan
Write-Host "Terraform + Ansible Deployment" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$tools = @{
    "terraform" = "terraform --version"
    "aws" = "aws --version"
    "ansible" = "ansible --version"
    "python" = "python --version"
}

$allPresent = $true
foreach ($tool in $tools.Keys) {
    try {
        $null = Invoke-Expression $tools[$tool] 2>&1
        Write-Host "✓ $tool installed" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ $tool not found" -ForegroundColor Red
        $allPresent = $false
    }
}

if (-not $allPresent) {
    Write-Host "`nPlease install missing tools before continuing." -ForegroundColor Red
    exit 1
}

# Step 1: Terraform Deployment
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 1: Deploying Infrastructure (Terraform)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Set-Location "$PSScriptRoot\..\infra"

if (-not (Test-Path "terraform.tfvars")) {
    Write-Host "⚠ terraform.tfvars not found!" -ForegroundColor Yellow
    Write-Host "Creating from example..." -ForegroundColor Yellow
    Copy-Item "terraform.tfvars.example" "terraform.tfvars"
    Write-Host "`n⚠ Please edit infra/terraform.tfvars with your settings:" -ForegroundColor Yellow
    Write-Host "  - Update db_password" -ForegroundColor Yellow
    Write-Host "  - Update allowed_ssh_cidr with your IP" -ForegroundColor Yellow
    Write-Host "`nPress Enter when ready to continue..."
    Read-Host
}

Write-Host "Initializing Terraform..." -ForegroundColor Green
terraform init

Write-Host "`nValidating configuration..." -ForegroundColor Green
terraform validate

Write-Host "`nGenerating plan..." -ForegroundColor Green
terraform plan -out=tfplan

Write-Host "`n⚠ Review the plan above. Ready to apply? (yes/no)" -ForegroundColor Yellow
$confirm = Read-Host

if ($confirm -ne "yes") {
    Write-Host "Deployment cancelled." -ForegroundColor Red
    exit 0
}

Write-Host "`nApplying Terraform configuration..." -ForegroundColor Green
Write-Host "This will take ~10-15 minutes..." -ForegroundColor Yellow
terraform apply tfplan

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n✗ Terraform deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n✓ Infrastructure deployed successfully!" -ForegroundColor Green

# Save outputs
Write-Host "`nSaving Terraform outputs..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "..\outputs" | Out-Null
terraform output > ..\outputs\terraform-output.txt
terraform output -json > ..\outputs\terraform-output.json

# Step 2: Generate Ansible Inventory
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 2: Generating Ansible Inventory" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Set-Location "$PSScriptRoot"
& ".\generate_inventory.ps1"

# Step 3: Install Ansible Dependencies
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 3: Installing Ansible Dependencies" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Set-Location "$PSScriptRoot\..\ansible"

Write-Host "Installing Python packages..." -ForegroundColor Green
pip install -r requirements.txt

Write-Host "`nInstalling Ansible collections..." -ForegroundColor Green
ansible-galaxy collection install -r requirements.yml

# Step 4: Test Connectivity
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 4: Testing Connectivity" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Waiting 30 seconds for EC2 to be fully ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "Testing SSH connectivity..." -ForegroundColor Green
ansible all -m ping -i inventory/hosts.ini

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n⚠ Connectivity test failed. Waiting 30 more seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    ansible all -m ping -i inventory/hosts.ini
}

# Step 5: Run Ansible Playbook
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Step 5: Configuring Servers (Ansible)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "⚠ Ready to run Ansible playbook? (yes/no)" -ForegroundColor Yellow
$confirm = Read-Host

if ($confirm -ne "yes") {
    Write-Host "Configuration cancelled. You can run it manually later:" -ForegroundColor Yellow
    Write-Host "  cd ansible" -ForegroundColor White
    Write-Host "  ansible-playbook -i inventory/hosts.ini playbook.yaml" -ForegroundColor White
    exit 0
}

Write-Host "`nRunning Ansible playbook..." -ForegroundColor Green
Write-Host "This will take ~5-10 minutes..." -ForegroundColor Yellow
ansible-playbook -i inventory/hosts.ini playbook.yaml -v

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n✗ Ansible configuration failed!" -ForegroundColor Red
    Write-Host "Check the output above for errors." -ForegroundColor Yellow
    exit 1
}

# Completion
Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✓ DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Infrastructure Details:" -ForegroundColor Cyan
Set-Location "$PSScriptRoot\..\infra"
terraform output deployment_summary

Write-Host "`nNext Steps:" -ForegroundColor Yellow
Write-Host "1. SSH to EC2: ssh -i ~/.ssh/id_rsa ec2-user@<EC2_IP>" -ForegroundColor White
Write-Host "2. Check Docker: docker --version" -ForegroundColor White
Write-Host "3. Deploy your application" -ForegroundColor White
Write-Host "4. Take screenshots for your assignment" -ForegroundColor White
Write-Host "5. When done, run: cd infra; terraform destroy" -ForegroundColor White

Write-Host "`n📝 Documentation:" -ForegroundColor Cyan
Write-Host "  - Deployment Guide: DEPLOYMENT_GUIDE.md" -ForegroundColor White
Write-Host "  - Free Tier Guide: FREE_TIER_GUIDE.md" -ForegroundColor White
Write-Host "  - Terraform README: infra/README.md" -ForegroundColor White
Write-Host "  - Ansible README: ansible/README.md" -ForegroundColor White

Write-Host "`nOutputs saved to: outputs/" -ForegroundColor Green
