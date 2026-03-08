#!/bin/bash

# Installs DCM4CHE (DICOM/PACS simulator) and Filebeat
# Runs on: Imaging Server (t3.micro, 10.0.1.20)

set -e
exec > /var/log/imaging_bootstrap.log 2>&1
echo "=== Imaging Server Bootstrap Starting ==="

# ---------------------------------------------------
# 1. Install Java (required for DCM4CHE) and tools
# ---------------------------------------------------
apt-get update -y
apt-get install -y default-jre wget unzip

# ---------------------------------------------------
# 2. Download and extract DCM4CHE
# ---------------------------------------------------
echo "Installing DCM4CHE..."
mkdir -p /opt/dcm4che
wget -q https://github.com/dcm4che/dcm4che/releases/download/5.31.0/dcm4che-5.31.0-bin.zip \
    -O /tmp/dcm4che.zip
unzip -q /tmp/dcm4che.zip -d /opt/dcm4che/
rm /tmp/dcm4che.zip  # cleanup

# ---------------------------------------------------
# 3. Create a systemd service for StoreSCP
# Running as a service means it survives reboots and
# restarts automatically - more reliable than nohup
# ---------------------------------------------------
cat > /etc/systemd/system/storescp.service <<'SERVICE'
[Unit]
Description=DCM4CHE StoreSCP - DICOM PACS Simulator
After=network.target

[Service]
ExecStart=/opt/dcm4che/dcm4che-5.31.0/bin/storescp --accept-all --port 104
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable storescp
systemctl start storescp
echo "StoreSCP running on port 104"

# ---------------------------------------------------
# 4. Install Filebeat
# ---------------------------------------------------
echo "Installing Filebeat..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch \
    | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] \
https://artifacts.elastic.co/packages/8.x/apt stable main" \
    | tee /etc/apt/sources.list.d/elastic-8.x.list

apt-get update -y && apt-get install -y filebeat

# ---------------------------------------------------
# 5. Configure Filebeat
# Ships /var/log/*.log to Logstash on The Brain
# ---------------------------------------------------
cat > /etc/filebeat/filebeat.yml <<'FILEBEAT'
filebeat.inputs:
  - type: filestream
    enabled: true
    paths:
      - /var/log/*.log

output.logstash:
  hosts: ["10.0.2.10:5044"]
FILEBEAT

systemctl enable filebeat
systemctl start filebeat
echo "Filebeat shipping logs to 10.0.2.10:5044"

echo "=== Imaging Server Bootstrap Complete ==="