# PowerShell Script to Generate Ansible Inventory from Terraform Outputs
# Run this script after terraform apply to populate the Ansible inventory

Write-Host "Generating Ansible inventory from Terraform outputs..." -ForegroundColor Green

# Change to infra directory
Set-Location "$PSScriptRoot\..\infra"

# Check if Terraform is initialized
if (-not (Test-Path ".terraform")) {
    Write-Host "⚠️  Terraform not initialized. Running terraform init..." -ForegroundColor Yellow
    terraform init
}

# Check if outputs exist
try {
    $null = terraform output -json ec2_public_ips 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Terraform outputs not found"
    }
} catch {
    Write-Host "❌ Error: Terraform outputs not found!" -ForegroundColor Red
    Write-Host "   Please run 'terraform apply' first to create infrastructure." -ForegroundColor Yellow
    exit 1
}

# Get Terraform outputs with error handling
try {
    $ec2IpsJson = terraform output -json ec2_public_ips 2>$null | ConvertFrom-Json
    if (-not $ec2IpsJson -or $ec2IpsJson.Count -eq 0) {
        Write-Host "⚠️  Warning: No EC2 instances found in Terraform outputs!" -ForegroundColor Yellow
        $ec2IpsJson = @()
    }
} catch {
    Write-Host "⚠️  Warning: Could not get EC2 IPs. Inventory will be empty." -ForegroundColor Yellow
    $ec2IpsJson = @()
}

try {
    $rdsEndpoint = terraform output -raw rds_endpoint 2>$null
    if (-not $rdsEndpoint) { $rdsEndpoint = "" }
} catch {
    $rdsEndpoint = ""
}

try {
    $rdsAddress = terraform output -raw rds_address 2>$null
    if (-not $rdsAddress) { $rdsAddress = "" }
} catch {
    $rdsAddress = ""
}

try {
    $dbUsername = terraform output -raw rds_username 2>$null
    if (-not $dbUsername) { $dbUsername = "dbadmin" }
} catch {
    $dbUsername = "dbadmin"
}

try {
    $dbName = terraform output -raw rds_database_name 2>$null
    if (-not $dbName) { $dbName = "devopsdb" }
} catch {
    $dbName = "devopsdb"
}

# Create inventory file path
$inventoryFile = "..\ansible\inventory\hosts.ini"

Write-Host "Writing to $inventoryFile..." -ForegroundColor Cyan

# Create inventory content
$inventoryContent = @"
# Auto-generated Ansible Inventory
# Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

[ec2_instances]
"@

# Add EC2 instances
if ($ec2IpsJson -and $ec2IpsJson.Count -gt 0) {
    $counter = 1
    foreach ($ip in $ec2IpsJson) {
        if ($ip -and $ip -ne "null") {
            $inventoryContent += "`nec2-$counter ansible_host=$ip"
            $counter++
        }
    }
}

$inventoryContent += @"

`n
[ec2_instances:vars]
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_python_interpreter=/usr/bin/python3

[app_servers]
"@

# Add app servers (same as EC2 instances)
if ($ec2IpsJson -and $ec2IpsJson.Count -gt 0) {
    $counter = 1
    foreach ($ip in $ec2IpsJson) {
        if ($ip -and $ip -ne "null") {
            $inventoryContent += "`nec2-$counter ansible_host=$ip"
            $counter++
        }
    }
}

$inventoryContent += @"

`n
[app_servers:vars]
app_name=devops-mid
app_port=5000
db_host=$rdsAddress
db_port=5432
db_name=$dbName
db_user=$dbUsername

[all:vars]
ansible_connection=ssh
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
"@

# Write to file
$inventoryContent | Out-File -FilePath $inventoryFile -Encoding UTF8 -Force

Write-Host "`n✅ Inventory file generated successfully!" -ForegroundColor Green
Write-Host "`nEC2 Instances:" -ForegroundColor Yellow
foreach ($ip in $ec2IpsJson) {
    Write-Host "  - $ip" -ForegroundColor White
}
Write-Host "`nRDS Endpoint: $rdsEndpoint" -ForegroundColor Yellow
Write-Host "`nYou can now run: cd ..\ansible; ansible-playbook -i inventory/hosts.ini playbook.yaml" -ForegroundColor Cyan
