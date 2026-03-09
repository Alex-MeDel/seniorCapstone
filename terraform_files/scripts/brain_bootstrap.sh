#!/bin/bash

# =======================================================
# DEPLOYMENT SCRIPT: The Brain (Management & Logging Server)
# Description: Provisions Docker, modifies kernel parameters for 
# Elasticsearch, retrieves ELK configuration from S3, and initializes containers.
# Target OS: Ubuntu 22.04 LTS | Instance: t3.large (10.0.2.10)
# =======================================================

# AI Disclosure:
# Claude AI helped me implement the S3 bucket solution within the existing bash script
# Google Gemini AI helped me polish the script and recommended different solutions while debugging


set -e  # Exit immediately if any command fails for debugging

# Redirect all stdout and stderr to a log file for deployment debugging
exec > /var/log/brain_bootstrap.log 2>&1  # Log everything
echo "=== Brain Bootstrap Starting ==="

# ---------------------------------------------------
# 1. Kernel Parameter Optimization (Elasticsearch Requirement)
# ---------------------------------------------------
# Without increasing the mmap counts, the Elasticsearch JVM will 
# crash immediately upon container initialization due to insufficient virtual memory.
# This was a Claude AI reommendation 
echo "Configuring vm.max_map_count for Elasticsearch..."
sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" >> /etc/sysctl.conf

# ---------------------------------------------------
# 2. Package Installation: Docker & AWS CLI
# ---------------------------------------------------
echo "Installing dependencies..."
apt-get update -y
apt-get install -y docker.io docker-compose awscli
systemctl enable docker
systemctl start docker

# ---------------------------------------------------
# 3. Secure Asset Retrieval (S3 via LabInstanceProfile)
# ---------------------------------------------------
# BUCKET_NAME is dynamically injected by Terraform's templatefile() function.
# Authentication is implicitly handled by the attached LabInstanceProfile IAM role.
echo "Pulling configuration assets from S3..."
mkdir -p /home/ubuntu/logstash/pipeline

# This pulls files from the S3 bucket
aws s3 cp s3://${bucket_name}/docker-compose.yml     /home/ubuntu/docker-compose.yml
aws s3 cp s3://${bucket_name}/logstash.conf          /home/ubuntu/logstash/pipeline/logstash.conf
aws s3 cp s3://${bucket_name}/validationScript.py    /home/ubuntu/validationScript.py

# Fix ownership so ubuntu user can interact with the files (No Sudo for everything)
chown -R ubuntu:ubuntu /home/ubuntu

# ---------------------------------------------------
# 4. Container Orchestration (Initialize ELK)
# ---------------------------------------------------
echo "Starting ELK stack via Docker Compose..."
cd /home/ubuntu
docker-compose up -d

echo "=== Brain Bootstrap Complete ==="
echo "Kibana will be available on port 5601 in about 5 minutes"