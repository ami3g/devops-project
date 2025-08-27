#!/bin/bash

# Update and install necessary packages
sudo yum update -y
sudo yum install -y python3-pip git docker

# Retrieve DB credentials from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id "${db_password_secret_name}" --query SecretString --output text --region us-east-1)
DB_ENDPOINT=$(aws secretsmanager get-secret-value --secret-id "${db_endpoint_secret_name}" --query SecretString --output text --region us-east-1)

# Set environment variables for the application
export DB_PASSWORD=$DB_PASSWORD
export DB_HOST=$DB_ENDPOINT

# Install Docker Compose
DOCKER_COMPOSE_VERSION="1.29.2"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Start the application
git clone https://github.com/amitesh945/devops-project-repo.git /home/ec2-user/devops-project
cd /home/ec2-user/devops-project
docker-compose up -d --build
