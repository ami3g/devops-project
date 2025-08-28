#!/bin/bash

# Update and install necessary packages
sudo yum update -y
sudo yum install -y docker

# Start the Docker service
sudo systemctl start docker
sudo usermod -a -G docker ec2-user

# Set environment variables for the application
export DB_PASSWORD="${db_password}"
export DB_HOST="${db_endpoint}"

# Run the Django application using Docker
docker run -p 5000:5000 your-docker-image-from-ecr