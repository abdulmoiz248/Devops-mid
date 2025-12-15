# Random suffix to avoid naming conflicts in CI/CD
resource "random_id" "db_suffix" {
  byte_length = 4
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-${random_id.db_suffix.hex}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }

  # Force replacement when subnets change to avoid VPC mismatch
  lifecycle {
    create_before_destroy = true
  }
}

# RDS PostgreSQL Instance
# Free Tier: db.t3.micro with 20GB storage, single-AZ, PostgreSQL
resource "aws_db_instance" "postgres" {
  identifier = "${var.project_name}-postgres-${random_id.db_suffix.hex}"

  engine = "postgres"
  # Let AWS pick a supported default engine version for your region
  # (previously hard-coded 16.4, which can fail if not available):
  # engine_version = "16.4"

  instance_class        = var.db_instance_class # Must be db.t3.micro or db.t4g.micro for free tier
  allocated_storage     = 20                    # Free tier: up to 20GB
  max_allocated_storage = 20                    # Disabled auto-scaling for free tier
  storage_type          = "gp2"                 # gp2 is free tier eligible, gp3 is not
  storage_encrypted     = false                 # Encryption not available on free tier

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  multi_az                 = false # Must be false for free tier
  backup_retention_period  = 0     # Disable backups for free tier
  skip_final_snapshot      = true
  delete_automated_backups = true

  # CloudWatch logs disabled for free tier
  # enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name = "${var.project_name}-postgres"
  }

  lifecycle {
    create_before_destroy = true
  }
}