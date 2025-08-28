# Security group to allow instances to communicate with the VPC endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "devops-project-vpc-endpoint-sg"
  description = "Allow TLS traffic to VPC endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Allow traffic from any resource within the VPC
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  tags = {
    Name = "devops-project-vpc-endpoint-sg"
  }
}

# S3 Gateway Endpoint: Allows yum/dnf to download packages (like Docker)
# This is a gateway type and gets associated with a route table.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  route_table_ids   = [aws_route_table.private.id] # We will create this route table next
  
  tags = {
    Name = "devops-project-s3-vpce"
  }
}

# ECR API Interface Endpoint: Allows the instance to authenticate with ECR
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "devops-project-ecr-api-vpce"
  }
}

# ECR DKR Interface Endpoint: Allows the instance to pull Docker images
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "devops-project-ecr-dkr-vpce"
  }
}

# Secrets Manager Interface Endpoint: Allows pulling DB credentials and SSH keys
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "devops-project-secretsmanager-vpce"
  }
}

# CloudWatch Logs Interface Endpoint: Allows instances to send logs
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true

  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id]

  tags = {
    Name = "devops-project-cloudwatch-logs-vpce"
  }
}
