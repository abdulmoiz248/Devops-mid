# PowerShell Script to Generate Ansible Inventory from Terraform Outputs
# Run this script after terraform apply to populate the Ansible inventory

Write-Host "Generating Ansible inventory from Terraform outputs..." -ForegroundColor Green

# Change to infra directory
Set-Location "$PSScriptRoot\..\infra"

# Get Terraform outputs
$ec2IpsJson = terraform output -json ec2_public_ips | ConvertFrom-Json
$rdsEndpoint = terraform output -raw rds_endpoint
$rdsAddress = terraform output -raw rds_address
$dbUsername = terraform output -raw rds_username
$dbName = terraform output -raw rds_database_name

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
$counter = 1
foreach ($ip in $ec2IpsJson) {
    $inventoryContent += "`nec2-$counter ansible_host=$ip"
    $counter++
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
$counter = 1
foreach ($ip in $ec2IpsJson) {
    $inventoryContent += "`nec2-$counter ansible_host=$ip"
    $counter++
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
