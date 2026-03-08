#!/bin/bash

# Installs Docker, runs Conpot medical template, installs Filebeat
# Runs on: IoT Gateway (t3.micro, 10.0.1.30)

set -e
exec > /var/log/iot_bootstrap.log 2>&1
echo "=== IoT Gateway Bootstrap Starting ==="

# ---------------------------------------------------
# 1. Install Docker and AWS CLI
# ---------------------------------------------------
apt-get update -y
apt-get install -y docker.io awscli
systemctl enable docker
systemctl start docker

# ---------------------------------------------------
# 2. Run Conpot with the medical template
# Port mapping fix vs original:
#   -p 80:80   (not 80:8888 - medical template listens on 80 internally)
#   -p 502:502 (Modbus)
# ---------------------------------------------------
echo "Starting Conpot..."
docker run -d \
    --name conpot_medical \
    -p 80:80 \
    -p 502:502 \
    --restart always \
    mushorg/conpot:latest --template medical

echo "Conpot running on ports 80 (HTTP) and 502 (Modbus)"

# ---------------------------------------------------
# 3. Install Filebeat
# ---------------------------------------------------
echo "Installing Filebeat..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch \
    | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] \
https://artifacts.elastic.co/packages/8.x/apt stable main" \
    | tee /etc/apt/sources.list.d/elastic-8.x.list

apt-get update -y && apt-get install -y filebeat

# ---------------------------------------------------
# 4. Configure Filebeat to capture Conpot container logs
# ---------------------------------------------------
cat > /etc/filebeat/filebeat.yml <<'FILEBEAT'
filebeat.inputs:
  - type: container
    paths:
      - /var/lib/docker/containers/*/*.log

output.logstash:
  hosts: ["10.0.2.10:5044"]
FILEBEAT

systemctl enable filebeat
systemctl start filebeat
echo "Filebeat shipping Conpot container logs to 10.0.2.10:5044"

echo "=== IoT Gateway Bootstrap Complete ==="