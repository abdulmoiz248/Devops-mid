# PowerShell script to import existing AWS resources into Terraform state
# This prevents "already exists" errors when running terraform apply

$ErrorActionPreference = "Continue"

$PROJECT_NAME = "devops-mid"

Write-Host "`n🔄 Importing existing AWS resources into Terraform state...`n" -ForegroundColor Yellow

# Function to import a resource
function Import-TerraformResource {
    param(
        [string]$ResourceType,
        [string]$ResourceName,
        [string]$ResourceId
    )
    
    Write-Host "Checking $ResourceType..." -ForegroundColor Yellow
    
    $output = terraform import $ResourceName $ResourceId 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Successfully imported: $ResourceType`n" -ForegroundColor Green
    } else {
        Write-Host "⚠️  Resource doesn't exist in AWS or already in Terraform state: $ResourceType`n" -ForegroundColor Yellow
    }
}

# Change to infra directory
Set-Location -Path $PSScriptRoot

# Import EC2 Key Pair
Import-TerraformResource `
    -ResourceType "EC2 Key Pair" `
    -ResourceName "aws_key_pair.deployer" `
    -ResourceId "$PROJECT_NAME-key"

# Import DB Subnet Group
Import-TerraformResource `
    -ResourceType "RDS DB Subnet Group" `
    -ResourceName "aws_db_subnet_group.main" `
    -ResourceId "$PROJECT_NAME-db-subnet-group"

# Optional: Import other resources if needed
# Uncomment and modify as needed:

# Import-TerraformResource `
#     -ResourceType "RDS Instance" `
#     -ResourceName "aws_db_instance.postgres" `
#     -ResourceId "$PROJECT_NAME-postgres"

Write-Host "`n✅ Import process completed!" -ForegroundColor Green
Write-Host "You can now run 'terraform plan' and 'terraform apply' safely." -ForegroundColor Yellow
