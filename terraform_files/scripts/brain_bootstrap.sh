#!/bin/bash

# Claude AI helped me implement the S3 bucket solution within the existing bash script
# Installs Docker, pulls docker-compose.yml from S3, launches ELK stack
# Runs on: The Brain (t3.large, 10.0.2.10)

set -e  # Exit immediately if any command fails
exec > /var/log/brain_bootstrap.log 2>&1  # Log everything
echo "=== Brain Bootstrap Starting ==="

# ---------------------------------------------------
# 1. System requirement for Elasticsearch
# Without this ES crashes immediately on startup
# ---------------------------------------------------
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# ---------------------------------------------------
# 2. Install Docker and AWS CLI
# ---------------------------------------------------
apt-get update -y
apt-get install -y docker.io docker-compose awscli
systemctl enable docker
systemctl start docker

# ---------------------------------------------------
# 3. Pull files from S3
# IAM role on this instance grants s3:GetObject
# BUCKET_NAME is injected by Terraform via templatefile()
# ---------------------------------------------------
echo "Pulling files from S3..."
mkdir -p /home/ubuntu/logstash/pipeline

aws s3 cp s3://${bucket_name}/docker-compose.yml     /home/ubuntu/docker-compose.yml
aws s3 cp s3://${bucket_name}/logstash.conf          /home/ubuntu/logstash/pipeline/logstash.conf

# Fix ownership so ubuntu user can interact with the files
chown -R ubuntu:ubuntu /home/ubuntu

# ---------------------------------------------------
# 4. Launch ELK stack
# ---------------------------------------------------
echo "Starting ELK stack..."
cd /home/ubuntu
docker-compose up -d

echo "=== Brain Bootstrap Complete ==="
echo "Kibana will be available on port 5601 in ~2 minutes"