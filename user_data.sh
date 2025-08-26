#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
chkconfig docker on

# The database password is passed in by Terraform
export DB_PASSWORD="${db_password}"

# Placeholder for your application's docker image
docker run -p 5000:8000 your-docker-image-from-ecr
