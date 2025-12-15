# Handling Existing AWS Resources in Terraform

## Problems Fixed

### Error 1: Duplicate Resources
When running Terraform apply, you may encounter errors like:
- ✅ FIXED: `InvalidKeyPair.Duplicate: The keypair already exists`
- ✅ FIXED: `DBSubnetGroupAlreadyExists: The DB subnet group already exists`

### Error 2: Free Tier Instance Type
- ✅ FIXED: `The specified instance type is not eligible for Free Tier`
  - Solution: Explicitly set `ec2_instance_type=t2.micro` in all Terraform commands

### Error 3: VPC Mismatch for DB Subnet Group
- ✅ FIXED: `The new Subnets are not in the same Vpc as the existing subnet group`
  - Solution: Delete old DB subnet group before creating new one with correct VPC

## Solution Overview

The pipeline now automatically:
1. **Cleans up** conflicting DB subnet group (wrong VPC)
2. **Imports** existing key pair (if it exists)
3. **Ensures** free tier instance types are used (`t2.micro`, `db.t3.micro`)
4. **Creates** fresh DB subnet group with correct VPC subnets

## Automated (CI/CD Pipeline)
The GitHub Actions workflow has been updated to automatically handle all issues:

**New Workflow Steps:**
1. ✅ **Clean Up Conflicting Resources** - Deletes old DB subnet group that was in wrong VPC
2. ✅ **Import Existing Resources** - Imports EC2 key pair if it exists
3. ✅ **Free Tier Enforcement** - Forces `t2.micro` instances and `db.t3.micro` database
4. ✅ **Fresh DB Subnet Group** - Creates new subnet group with correct VPC

**No manual action needed** - the pipeline handles everything automatically!

### Manual Import (Local Development)

#### Option 1: Using the Import Script (Recommended)

**Linux/Mac:**
```bash
cd infra
./import-existing-resources.sh
```

**Windows (PowerShell):**
```powershell
cd infra
.\import-existing-resources.ps1
```

#### Option 2: Manual Terraform Import Commands

```bash
cd infra

# Initialize Terraform first
terraform init

# Import EC2 Key Pair (if exists)
terraform import aws_key_pair.deployer devops-mid-key

# Import DB Subnet Group (if exists)
terraform import aws_db_subnet_group.main devops-mid-db-subnet-group

# Now run plan and apply
terraform plan
terraform apply
```

## How It Works

### In GitHub Actions Workflow
The workflow includes a new step **before** `terraform plan`:

```yaml
- name: Clean Up Conflicting Resources
  run: |
    # Delete DB subnet group if it exists (will be recreated with correct VPC)
    aws rds delete-db-subnet-group --db-subnet-group-name devops-mid-db-subnet-group || true
    sleep 10

- name: Import Existing Resources (if any)
  run: |
    # Try to import existing key pair
    terraform import -var="ec2_instance_type=t2.micro" ... aws_key_pair.deployer "devops-mid-key" || true
  continue-on-error: true

- name: Terraform Plan
  run: |
    terraform plan \
      -var="ec2_instance_type=t2.micro" \
      -var="ec2_instance_count=1" \
      -var="db_instance_class=db.t3.micro" \
      ...
```

This step:
- ✅ Deletes conflicting DB subnet group (fixes VPC mismatch)
- ✅ Imports key pair if it exists in AWS
- ✅ Adds them to Terraform state
- ✅ Enforces free tier instance types
- ✅ Creates fresh DB subnet group with correct VPC
- ✅ Continues pipeline execution regardless of cleanup/import success

### Terraform State Management
Once imported, Terraform will:
- ✅ Recognize the resources as already managed
- ✅ Update them instead of trying to create new ones
- ✅ Show `0 to add, N to change, 0 to destroy` in plan

## Resources That Can Be Imported

Currently configured to handle:
1. **EC2 Key Pair**: `aws_key_pair.deployer` → Imported if exists
2. **DB Subnet Group**: Deleted and recreated (fixes VPC mismatch)
3. **Instance Types**: Forced to free tier (`t2.micro`, `db.t3.micro`)

## Adding More Resources to Import

To import additional resources, edit the import scripts or GitHub Actions workflow:

### Example: Import RDS Instance
```bash
terraform import aws_db_instance.postgres devops-mid-postgres
```

### In GitHub Actions:
Add to the "Import Existing Resources" step:
```yaml
terraform import -var="..." aws_db_instance.postgres "devops-mid-postgres" 2>/dev/null || true
```

## Troubleshooting

### Error: "Resource not found"
- The resource doesn't exist in AWS yet
- This is normal - Terraform will create it during apply

### Error: "Resource already in state"
- The resource is already tracked by Terraform
- No action needed - this is expected

### Import fails with authentication error
- Check AWS credentials are configured
- Verify IAM permissions include necessary read access

### State file conflicts
- Ensure only one Terraform operation runs at a time
- Check for stale state locks: `terraform force-unlock <LOCK_ID>`

## Best Practices

1. **Always run import before apply** when switching between environments
2. **Use the automated scripts** to avoid manual errors
3. **Check the plan output** before applying to verify what will change
4. **Keep state file secure** - it may contain sensitive data
5. **Use remote state** (S3 + DynamoDB) for team collaboration

## Files Modified

- ✅ `.github/workflows/main.yml` - Added import step
- ✅ `infra/import-existing-resources.sh` - Bash import script
- ✅ `infra/import-existing-resources.ps1` - PowerShell import script
- ✅ `infra/ec2.tf` - Resource definitions (unchanged)
- ✅ `infra/rds.tf` - Resource definitions (unchanged)

## Next Steps

After import, you can safely run:
```bash
terraform plan   # Review changes
terraform apply  # Apply changes
```

The pipeline will automatically handle imports on every run, so future deployments will work smoothly! 🚀
