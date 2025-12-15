# Data source for latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# SSH Key Pair
# For CI/CD: Pass public key via variable
# For local: Use file() function
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = var.ssh_public_key != "" ? var.ssh_public_key : file(pathexpand("~/.ssh/id_rsa.pub"))

  tags = {
    Name = "${var.project_name}-key"
  }
}

# EC2 Instances
resource "aws_instance" "app" {
  count                  = var.ec2_instance_count
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public[count.index % length(aws_subnet.public)].id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = aws_key_pair.deployer.key_name

  user_data = <<-EOF
              #!/bin/bash
              # Update system
              yum update -y
              
              # Install Docker
              yum install -y docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              
              # Install Docker Compose
              curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              chmod +x /usr/local/bin/docker-compose
              
              # Install Git
              yum install -y git
              
              # Install Python 3 and pip
              yum install -y python3 python3-pip
              
              # Create application directory
              mkdir -p /opt/app
              chown ec2-user:ec2-user /opt/app
              
              echo "EC2 instance setup complete" > /var/log/user-data.log
              EOF

  root_block_device {
    volume_size           = 30  # Minimum required by AMI snapshot
    volume_type           = "gp2"  # gp2 is free tier eligible
    delete_on_termination = true
  }

  tags = {
    Name = "${var.project_name}-ec2-${count.index + 1}"
  }
}

# Application Load Balancer (Optional - costs ~$16/month)
resource "aws_lb" "app" {
  count              = var.create_alb ? 1 : 0
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# Target Group
resource "aws_lb_target_group" "app" {
  count    = var.create_alb ? 1 : 0
  name     = "${var.project_name}-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# Register EC2 instances with target group
resource "aws_lb_target_group_attachment" "app" {
  count            = var.create_alb ? var.ec2_instance_count : 0
  target_group_arn = aws_lb_target_group.app[0].arn
  target_id        = aws_instance.app[count.index].id
  port             = 5000
}

# ALB Listener
resource "aws_lb_listener" "app" {
  count             = var.create_alb ? 1 : 0
  load_balancer_arn = aws_lb.app[0].arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app[0].arn
  }
}
