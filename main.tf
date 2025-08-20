terraform {
  required_providers {
    # The AWS provider is what allows Terraform to interact with AWS services.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# The provider block configures the AWS provider with the specific region
# where all your resources will be created.
provider "aws" {
  region = "us-east-1" # You can choose a different region if you prefer
}

data "aws_availability_zones" "available" {
  state = "available"
}

# This resource creates a Virtual Private Cloud (VPC), which is a logically isolated
# virtual network for your AWS resources.
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "devops-project-vpc"
  }
}

# This resource creates two public subnets within the VPC. Public subnets can
# communicate with the internet.
resource "aws_subnet" "public" {
  count = 2 # Create two subnets for high availability

  vpc_id                = aws_vpc.main.id
  cidr_block            = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone     = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "devops-project-public-subnet-${count.index}"
  }
}

# This resource creates an Internet Gateway (IGW) to enable communication between
# the VPC and the internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-project-igw"
  }
}

# This resource creates a route table. A route table contains a set of rules
# that determine where network traffic is directed.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "devops-project-public-rt"
  }
}

# This resource associates the public subnets with the public route table,
# making them accessible from the internet.
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Resource to create an ECR repository to store your Docker image
resource "aws_ecr_repository" "app" {
  name                 = "devops-project-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

# IAM Role for EC2 instances
resource "aws_iam_role" "ec2_instance_role" {
  name = "devops-project-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

# Attach a policy to the IAM role that allows EC2 to pull images from ECR
resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# IAM instance profile is a container for an IAM role that you can use to pass role information to an EC2 instance.
resource "aws_iam_instance_profile" "instance_profile" {
  name = "devops-project-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

# Security Group for the Application Load Balancer to allow web traffic
resource "aws_security_group" "lb_sg" {
  name        = "devops-project-lb-sg"
  description = "Allow inbound traffic from internet to ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group to allow traffic to the EC2 instances
resource "aws_security_group" "app_sg" {
  name        = "devops-project-app-sg"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.main.id

  # Inbound rule to allow traffic from the Load Balancer
  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-project-app-sg"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "devops-project-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name = "devops-project-alb"
  }
}

# Target Group for the Load Balancer
resource "aws_lb_target_group" "app_target_group" {
  name     = "devops-project-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# Listener for the Load Balancer
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    type             = "forward"
  }
}

# Launch Template to define the EC2 instances
resource "aws_launch_template" "app_template" {
  name_prefix   = "devops-project-app-template"
  image_id      = "ami-00ca32bbc84273381" # Amazon Linux 2 AMI
  instance_type = "t2.micro"

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
  }

 # User data to install and run the Dockerized app
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install docker -y
              service docker start
              usermod -a -G docker ec2-user
              # Wait for Docker to be ready
              until docker info; do
                echo "Waiting for Docker daemon to be ready..."
                sleep 1
              done
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}
              docker pull ${aws_ecr_repository.app.repository_url}:latest
              docker run -d -p 5000:5000 ${aws_ecr_repository.app.repository_url}:latest
              EOF
  )

  tags = {
    Name = "devops-project-app-template"
  }
}

# Auto Scaling Group to manage the number of instances
resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.app_target_group.arn]

  launch_template {
    id      = aws_launch_template.app_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "devops-project-asg"
    propagate_at_launch = true
  }
}