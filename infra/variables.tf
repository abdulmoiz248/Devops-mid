variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "devops-mid"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "ec2_instance_type" {
  description = "EC2 instance type - MUST be t2.micro or t3.micro for Free Tier"
  type        = string
  default     = "t2.micro"  # Free Tier eligible: t2.micro (most regions) or t3.micro

  validation {
    condition     = contains(["t2.micro", "t3.micro"], var.ec2_instance_type)
    error_message = "For Free Tier, instance type must be t2.micro or t3.micro."
  }
}

variable "ec2_instance_count" {
  description = "Number of EC2 instances"
  type        = number
  default     = 1  # Set to 1 for free tier, can be increased to 2
}

variable "db_instance_class" {
  description = "RDS instance class - MUST be db.t3.micro or db.t4g.micro for Free Tier"
  type        = string
  default     = "db.t3.micro"  # Free Tier eligible

  validation {
    condition     = contains(["db.t3.micro", "db.t4g.micro"], var.db_instance_class)
    error_message = "For Free Tier, DB instance class must be db.t3.micro or db.t4g.micro."
  }
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "devopsdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR blocks allowed to SSH to EC2 instances"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for better security
}

variable "create_nat_gateway" {
  description = "Whether to create NAT Gateway (costs ~$32/month). Set to false for free tier."
  type        = bool
  default     = false  # Set to false to save costs on free tier
}

variable "create_alb" {
  description = "Whether to create Application Load Balancer (costs ~$16/month). Set to false for free tier."
  type        = bool
  default     = false  # Set to false to save costs, access EC2 directly
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access. Leave empty to use ~/.ssh/id_rsa.pub"
  type        = string
  default     = ""
  sensitive   = false
}

variable "docker_image" {
  description = "Docker image to deploy on EC2 instances"
  type        = string
  default     = "devops-mid:latest"
}
