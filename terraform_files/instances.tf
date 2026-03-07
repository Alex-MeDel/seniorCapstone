# ==========================================
# STEP 3: COMPUTE RESOURCES (The Virtual Servers)
# These are the actual computers that will run our hospital software
# ==========================================

# The Brain (Ubuntu 22.04 + ELK Docker) 
# A powerful server used to run the ELK stack for data visualization
# t3.large is important due to resourse consuption of the ELK Stack surpasing what a t3.medium can provide
resource "aws_instance" "the_brain" {
    ami                    = var.brain_ami
    instance_type          = "t3.large"
    subnet_id              = aws_subnet.brain_zone.id
    vpc_security_group_ids = [aws_security_group.brain_sg.id]
    private_ip             = "10.0.2.10"
    key_name               = aws_key_pair.honeypot_key.key_name  # This is part of SSH config
    associate_public_ip_address = true   # This line will give the brain access to a public IP address for bootstraping
    tags                   = { Name = "The-Brain-ELK" }

    # CONFIGURE EVERYTHING ON STARTUP!!!
    # Also creates and RUNS the Docker-Compose File - Cant do due to having multiple heredocs (bash and terraform would likely break the YAML formating and break everything)
    # Proposed solution: An S3 bucket in Terraform to store the file 
    # Will try to do Docker-Compose YAML here first and if it fails will do S3 bucket solution
    # Used AI to try to fix text alignment issues in heredocs before they happen, hoping for best
    user_data = <<-EOF
      #!/bin/bash
      # 1. System Requirements
      sysctl -w vm.max_map_count=262144
      echo "vm.max_map_count=262144" >> /etc/sysctl.conf
      
      # 2. Dependencies
      apt-get update -y
      apt-get install -y docker.io docker-compose
      systemctl enable docker
      systemctl start docker

      mkdir -p /home/ubuntu/logstash/pipeline

      # 3. Write Logstash Config (Note the unique delimiter in the cat, this for alignment and YAML spacing problems)
      cat <<'LOG_CONFIG' > /home/ubuntu/logstash/pipeline/logstash.conf
input {
  beats { port => 5044 }
}
output {
  elasticsearch { hosts => ["elasticsearch:9200"] }
}
LOG_CONFIG

      # 4. Write Docker Compose file (Essentially a copy paste without comments)
      cat <<'COMPOSE_FILE' > /home/ubuntu/docker-compose.yml
version: '3.8'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.10.2
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
      - xpack.security.enabled=false
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - es_data:/usr/share/elasticsearch/data
    ports:
      - 9200:9200
    networks:
      - honeypot-net

  logstash:
    image: docker.elastic.co/logstash/logstash:8.10.2
    container_name: logstash
    volumes:
      - ./logstash/pipeline:/usr/share/logstash/pipeline:ro
    ports:
      - 5044:5044 # Port for incoming Beats (Winlogbeat/Filebeat)
    environment:
      - LS_JAVA_OPTS=-Xms1g -Xmx1g
    depends_on:
      - elasticsearch
    networks:
      - honeypot-net

  kibana:
    image: docker.elastic.co/kibana/kibana:8.10.2
    container_name: kibana
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - 5601:5601 # Accessible via AWS Client VPN
    depends_on:
      - elasticsearch
    networks:
      - honeypot-net


networks:
  honeypot-net:
    driver: bridge
    
volumes:
  es_data:
    driver: local

COMPOSE_FILE

      # 5. Execute
      cd /home/ubuntu
      docker-compose up -d
EOF
}

# Medical Workstation (Windows 7 or 2012 Legacy) - Still deciding
# Simulates an old Windows computer used by nurses or doctors
resource "aws_instance" "win_workstation" {
    ami                    = var.win_ami # Windows Server 2012 
    instance_type          = "t3.medium"
    subnet_id              = aws_subnet.clinical_zone.id 
    vpc_security_group_ids = [aws_security_group.clinical_sg.id] 
    key_name               = aws_key_pair.honeypot_key.key_name  # This is part of SSH config
    # IMPORTANT!!!! Once the initial terraform apply finishes and there is Kibana verification and comment out this FIX to remove internet access
    associate_public_ip_address = true   # <-- THE FIX for internet while bootstraping 
    tags                   = { Name = "Win-Clinical-Workstation" } 

    # This part attempts to automate the Windows 2012 Legacy Server Instance 
    # I dont know any PowerShell, so this is 100% AI generated code, NEEDS REVISION!!!!
    user_data = <<-EOF
    <powershell>
    # Start logging to troubleshoot if something fails during deployment
    Start-Transcript -Path "C:\userdata_transcript.txt"

    # 1. Open Windows Firewall for SMB and ICMP (for validationScript.py)
    netsh advfirewall firewall add rule name="Allow SMB" dir=in action=allow protocol=TCP localport=445
    netsh advfirewall firewall add rule name="Allow Ping" protocol=icmpv4 dir=in action=allow

    # 2. Download and Install Winlogbeat (The log shipper)
    $url = "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-8.10.2-windows-x86_64.zip"
    $dest = "C:\winlogbeat.zip"

    # Added -UseBasicParsing to prevent Internet Explorer first-run errors
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing

    # Replaced Expand-Archive with .NET method for PowerShell 3.0/4.0 compatibility
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($dest, "C:\")
    Rename-Item "C:\winlogbeat-8.10.2-windows-x86_64" "C:\winlogbeat"

    # 3. Configure Winlogbeat to point to The Brain (10.0.2.10) 
    $config = @"
    winlogbeat.event_logs:
    - name: Application
    - name: Security
    - name: System

    output.logstash:
    hosts: ["10.0.2.10:5044"]
    "@
    $config | Out-File -FilePath "C:\winlogbeat\winlogbeat.yml" -Encoding utf8

    # 4. Install and Start the Service
    cd C:\winlogbeat
    # Bypassing the execution policy so the install script can run
    PowerShell.exe -ExecutionPolicy Bypass -File .\install-service-winlogbeat.ps1
    Start-Service winlogbeat

    Stop-Transcript
    </powershell>
    EOF
}

# Imaging Server (Ubuntu + DICOM Sim) 
# Mimics a PACS system used to store X-rays and MRI scans
resource "aws_instance" "imaging_server" {
    ami                    = var.brain_ami # Ubuntu 22.04 AMI ID
    instance_type          = "t3.micro"
    subnet_id              = aws_subnet.clinical_zone.id
    vpc_security_group_ids = [aws_security_group.clinical_sg.id]
    private_ip             = "10.0.1.20"
    key_name               = aws_key_pair.honeypot_key.key_name  # This is part of SSH config
    associate_public_ip_address = true   # <-- THE FIX for internet while bootstraping 
    tags                   = { Name = "Imaging-Server-PACS" }

    # AUTOMATE EVERYTHING!!! 
    user_data = <<-EOF
      #!/bin/bash
      # 1. Update and install Java (Required for DCM4CHE)
      apt-get update -y
      apt-get install -y default-jre wget unzip

      # 2. Download DCM4CHE (DICOM Toolkit)
      mkdir -p /opt/dcm4che
      wget https://github.com/dcm4che/dcm4che/releases/download/5.31.0/dcm4che-5.31.0-bin.zip -O /tmp/dcm4che.zip
      unzip /tmp/dcm4che.zip -d /opt/dcm4che/

      # 3. Start the DICOM Network Receiver (StoreSCP)
      # This mimics a PACS system listening on the standard DICOM port 104
      # Running in the background so the instance stays active
      nohup /opt/dcm4che/dcm4che-5.31.0/bin/storescp --accept-all --port 104 &
      
      # 4. Install Filebeat for log forwarding to The Brain 
      wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list
      apt-get update && apt-get install filebeat -y

      # 5. Configure Filebeat to send to The Brain (10.0.2.10)
      cat <<'LOG_SHIP' > /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: filestream
  enabled: true
  paths:
    - /var/log/*.log
output.logstash:
  hosts: ["10.0.2.10:5044"]
LOG_SHIP

      systemctl enable filebeat
      systemctl start filebeat
    EOF
}

# IoT Gateway (Ubuntu + Conpot Docker)
# A specialized tool (Conpot) that pretends to be a medical device
resource "aws_instance" "iot_gateway" {
    ami                    = var.brain_ami # Ubuntu 22.04
    instance_type          = "t3.micro"
    subnet_id              = aws_subnet.clinical_zone.id
    vpc_security_group_ids = [aws_security_group.clinical_sg.id]
    private_ip             = "10.0.1.30"
    key_name               = aws_key_pair.honeypot_key.key_name  # This is part of SSH config
    associate_public_ip_address = true   # <-- THE FIX for internet while bootstraping 
    tags                   = { Name = "IoT-Gateway-Conpot" }

    # AUTOMATE EVERYTHING!!! 
    # This will install docker and run conpot to mimic medical equipment, will also install and configure filebeat
    user_data = <<-EOF
      #!/bin/bash
      # 1. Install Docker
      apt-get update -y
      apt-get install -y docker.io
      systemctl enable docker
      systemctl start docker

      # 2. Run Conpot with the Medical Template
      # This maps Modbus (502) and HTTP (80) to mimic medical hardware
      docker run -d --name conpot_medical \
        -p 80:8888 \
        -p 502:502 \
        --restart always \
        mushorg/conpot:latest --template medical

      # 3. Install and Configure Filebeat for Log Shipping to The Brain (10.0.2.10)
      wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elastic-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/elastic-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list
      apt-get update && apt-get install filebeat -y

      cat <<'LOG_SHIP' > /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: container
  paths:
    - /var/lib/docker/containers/*/*.log
output.logstash:
  hosts: ["10.0.2.10:5044"]
LOG_SHIP

      systemctl enable filebeat
      systemctl start filebeat
    EOF
}
