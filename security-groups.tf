# Security group for the EC2 instance running the application.
resource "aws_security_group" "app_sg" {
  name        = "devops-project-app-sg"
  description = "Allow inbound HTTP and SSH traffic"
  vpc_id      = aws_vpc.main.id

  # Allow inbound HTTP traffic on port 80 from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound SSH traffic from anywhere (for debugging)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic from the Load Balancer
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb_sg.id]
  }
}

# Security group for the EC2 Load Balancer
resource "aws_security_group" "lb_sg" {
  name        = "devops-project-lb-sg"
  description = "Allow inbound HTTP traffic to the load balancer"
  vpc_id      = aws_vpc.main.id

  # Allow inbound HTTP traffic on port 80 from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security group for the RDS DB instance
resource "aws_security_group" "db_security_group" {
  name        = "devops-project-db-sg"
  description = "Allow inbound traffic from the application servers"
  vpc_id      = aws_vpc.main.id

  # Allow inbound traffic on port 5432 (PostgreSQL) from the application security group
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
}