# Main Terraform configuration file
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket         = "devops-project-terraform-state-amite"
    key            = "main/terraform.tfstate"
    region         = "us-east-1"
    # IMPORTANT: Temporarily commented out to fix the destroy error.
    # dynamodb_table = "devops-project-terraform-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Added enable_dns_support and enable_dns_hostnames to the VPC resource
resource "aws_vpc" "main" {
  cidr_block         = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "devops-project-vpc"
  }
}

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "devops-project-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.${count.index * 16}/28"
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "devops-project-private-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-project-igw"
  }
}

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

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route table for the private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "devops-project-private-rt"
  }
}

# Associate the private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_ecr_repository" "app" {
  name                 = "devops-project-app"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  # CRITICAL: This line forces the repository and its images to be deleted.
  force_delete = true
}

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

resource "aws_iam_role_policy_attachment" "ecr_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Generate a unique ID for the secret name
resource "random_uuid" "ssh_secret_id" {}

# Create a new secret in Secrets Manager to store the public key
resource "aws_secretsmanager_secret" "bastion_ssh_key" {
  name        = "devops-project-bastion-ssh-pub-key-${random_uuid.ssh_secret_id.id}"
  description = "SSH public key for bastion host authentication"
}

# Add a secret version with the actual public key string
resource "aws_secretsmanager_secret_version" "bastion_ssh_key_version" {
  secret_id = aws_secretsmanager_secret.bastion_ssh_key.id
  secret_string = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBDCwxtOxTM2v7NqKXRPIsm6B8rGbZJd0GrrElKoSdH8 amite@ami"
}

# Define an Amazon RDS DB instance
resource "aws_db_instance" "devops_project_db" {
  vpc_security_group_ids = [aws_security_group.db_security_group.id]
  db_subnet_group_name   = aws_db_subnet_group.devops_project_db_subnet_group.name

  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "16.10"
  instance_class          = "db.t3.micro"
  db_name                 = "devops_project_db"
  username                = "projectadmin"
  password                = random_password.devops_project_db_password.result

  apply_immediately       = true
  skip_final_snapshot     = true
  publicly_accessible     = false
  backup_retention_period = 7

  tags = {
    Name = "devops-project-db"
  }

  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "random_password" "devops_project_db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()_+-=[]{}|:<>?,."
}

resource "aws_db_subnet_group" "devops_project_db_subnet_group" {
  subnet_ids = [aws_subnet.private[0].id, aws_subnet.private[1].id]
  tags = {
    Name = "devops-project-db-subnet-group"
  }
}

# Create a new secret for the DB password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password_secret" {
  name        = "devops-project-db-password"
  description = "RDS DB password"
}

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = random_password.devops_project_db_password.result
}

# Create a new secret for the DB endpoint
resource "aws_secretsmanager_secret" "db_endpoint_secret" {
  name        = "devops-project-db-endpoint"
  description = "RDS DB endpoint"
}

resource "aws_secretsmanager_secret_version" "db_endpoint_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_endpoint_secret.id
  secret_string = aws_db_instance.devops_project_db.address
}

# Policy to allow reading the SSH key and DB credentials from Secrets Manager
resource "aws_iam_policy" "secrets_manager_policy" {
  name         = "devops-project-secrets-manager-policy"
  description  = "Allows EC2 instances to read the SSH public key and DB credentials from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect  = "Allow"
        Action  = "secretsmanager:GetSecretValue"
        Resource = [
          aws_secretsmanager_secret.bastion_ssh_key.arn,
          aws_secretsmanager_secret.db_password_secret.arn,
          aws_secretsmanager_secret.db_endpoint_secret.arn,
        ]
      },
    ]
  })
}

# Attach the new policy to the EC2 role
resource "aws_iam_role_policy_attachment" "secrets_manager_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = "devops-project-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

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

resource "aws_lb_target_group" "app_target_group" {
  name     = "devops-project-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    type             = "forward"
  }
}

resource "aws_launch_template" "app_template" {
  name_prefix      = "devops-project-app-template"
  image_id         = "ami-00ca32bbc84273381"
  instance_type    = "t2.micro"
  key_name         = "ProjectKeyPair"

  iam_instance_profile {
    name = aws_iam_instance_profile.instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.app_sg.id]
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_password = aws_secretsmanager_secret_version.db_password_secret_version.secret_string
    db_endpoint = aws_secretsmanager_secret_version.db_endpoint_secret_version.secret_string
    ecr_repo_url = aws_ecr_repository.app.repository_url
  }))

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "devops-project-app-template"
  }
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = aws_subnet.private[*].id
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

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "devops-project-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "devops-project-terraform-lock-table"
  }
}

resource "aws_sns_topic" "devops_alerts" {
  name = "devops-project-alerts"
}

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.devops_alerts.arn
  protocol  = "email"
  endpoint  = "amitesh3000@yahoo.com"
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "devops-project-alb-5xx-errors"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_description = "Alarm when ALB returns 5xx errors"
  alarm_actions     = [aws_sns_topic.devops_alerts.arn]
  ok_actions        = [aws_sns_topic.devops_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_high" {
  alarm_name          = "devops-project-asg-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_description = "Alarm when average ASG CPU utilization is too high"
  alarm_actions     = [aws_sns_topic.devops_alerts.arn]
  ok_actions        = [aws_sns_topic.devops_alerts.arn]
}

resource "aws_instance" "bastion" {
  ami                 = "ami-00ca32bbc84273381"
  instance_type       = "t2.micro"
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id           = aws_subnet.public[0].id
  key_name            = "ProjectKeyPair"
  associate_public_ip_address = true
  source_dest_check     = false

  iam_instance_profile = aws_iam_instance_profile.instance_profile.name

  user_data = <<-EOF
      #!/bin/bash
      sudo yum update -y
      sudo yum install -y git
      aws secretsmanager get-secret-value --secret-id "${aws_secretsmanager_secret.bastion_ssh_key.name}" --query SecretString --output text > /home/ec2-user/bastion_ssh.pub
      cat /home/ec2-user/bastion_ssh.pub >> /home/ec2-user/.ssh/authorized_keys
      chmod 600 /home/ec2-user/.ssh/authorized_keys
      chown ec2-user:ec2-user /home/ec2-user/.ssh/authorized_keys
      EOF

  tags = {
    Name = "devops-project-bastion-host"
  }
}
