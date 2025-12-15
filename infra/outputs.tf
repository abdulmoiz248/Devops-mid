# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# Security Group Outputs
output "ec2_security_group_id" {
  description = "ID of EC2 security group"
  value       = aws_security_group.ec2.id
}

output "rds_security_group_id" {
  description = "ID of RDS security group"
  value       = aws_security_group.rds.id
}

output "alb_security_group_id" {
  description = "ID of ALB security group"
  value       = aws_security_group.alb.id
}

# EC2 Outputs
output "ec2_instance_ids" {
  description = "IDs of EC2 instances"
  value       = aws_instance.app[*].id
}

output "ec2_public_ips" {
  description = "Public IP addresses of EC2 instances"
  value       = aws_instance.app[*].public_ip
}

output "ec2_private_ips" {
  description = "Private IP addresses of EC2 instances"
  value       = aws_instance.app[*].private_ip
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.app[0].dns_name : "ALB not created (disabled for free tier)"
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.app[0].zone_id : null
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.create_alb ? aws_lb.app[0].arn : null
}

# RDS Outputs
output "rds_endpoint" {
  description = "Connection endpoint for RDS PostgreSQL"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_address" {
  description = "Address of RDS PostgreSQL"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Port of RDS PostgreSQL"
  value       = aws_db_instance.postgres.port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = aws_db_instance.postgres.db_name
}

output "rds_username" {
  description = "Master username for RDS"
  value       = aws_db_instance.postgres.username
  sensitive   = true
}

# Summary Output
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    vpc_id              = aws_vpc.main.id
    ec2_count           = length(aws_instance.app)
    ec2_public_ips      = aws_instance.app[*].public_ip
    alb_enabled         = var.create_alb
    alb_dns             = var.create_alb ? aws_lb.app[0].dns_name : "Not created (free tier mode)"
    rds_endpoint        = aws_db_instance.postgres.endpoint
    application_url     = var.create_alb ? "http://${aws_lb.app[0].dns_name}" : "http://${aws_instance.app[0].public_ip}:5000"
    nat_gateway_enabled = var.create_nat_gateway
  }
}

# Connection Information
output "ssh_connection_commands" {
  description = "SSH connection commands for EC2 instances"
  value = [
    for idx, instance in aws_instance.app :
    "ssh -i ~/.ssh/id_rsa ec2-user@${instance.public_ip}"
  ]
}

output "database_connection_string" {
  description = "Database connection string (password hidden)"
  value       = "postgresql://${aws_db_instance.postgres.username}:<password>@${aws_db_instance.postgres.endpoint}/${aws_db_instance.postgres.db_name}"
  sensitive   = true
}
