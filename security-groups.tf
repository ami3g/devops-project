# The Load Balancer Security Group
resource "aws_security_group" "lb_sg" {
  name        = "devops-project-lb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  # Ingress rule for HTTP traffic from the internet
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Egress rule allowing all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-project-lb-sg"
  }
}

# The Application Security Group
resource "aws_security_group" "app_sg" {
  name        = "devops-project-app-sg"
  description = "Security group for the application servers"
  vpc_id      = aws_vpc.main.id

  # Now using a standalone rule for the egress traffic.
  # This makes the rules independent from the security group itself.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-project-app-sg"
  }
}

# Standalone Ingress rule for the Application SG
# This allows traffic from the Load Balancer SG
resource "aws_security_group_rule" "app_ingress_lb" {
  type              = "ingress"
  from_port         = 5000
  to_port           = 5000
  protocol          = "tcp"
  source_security_group_id = aws_security_group.lb_sg.id
  security_group_id = aws_security_group.app_sg.id
}

# Standalone Ingress rule for the Application SG
# This allows SSH traffic from the Bastion SG
resource "aws_security_group_rule" "app_ingress_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = aws_security_group.bastion_sg.id
  security_group_id = aws_security_group.app_sg.id
}

# The Bastion Host Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "devops-project-bastion-sg"
  description = "Security group for the Bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-project-bastion-sg"
  }
}

# The Database Security Group
resource "aws_security_group" "db_security_group" {
  name        = "devops-project-db-sg"
  description = "Security group for the RDS database"
  vpc_id      = aws_vpc.main.id

  # Egress rule for database
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-project-db-sg"
  }
}

# Standalone Ingress rule for the Database SG
# This allows traffic from the Application SG
resource "aws_security_group_rule" "db_ingress_app" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  source_security_group_id = aws_security_group.app_sg.id
  security_group_id = aws_security_group.db_security_group.id
}
 