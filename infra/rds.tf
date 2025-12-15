# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
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
  identifier             = "${var.project_name}-postgres"
  engine                 = "postgres"
  engine_version         = "15.7"  # Use available version (check: aws rds describe-db-engine-versions --engine postgres)
  instance_class         = var.db_instance_class  # Must be db.t3.micro or db.t4g.micro for free tier
  allocated_storage      = 20  # Free tier: up to 20GB
  max_allocated_storage  = 20  # Disabled auto-scaling for free tier
  storage_type           = "gp2"  # gp2 is free tier eligible, gp3 is not
  storage_encrypted      = false  # Encryption not available on free tier

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  multi_az               = false  # Must be false for free tier
  backup_retention_period = 0  # Must be 0 for free tier
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"

  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # CloudWatch logs disabled for free tier
  # enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name = "${var.project_name}-postgres"
  }
}
