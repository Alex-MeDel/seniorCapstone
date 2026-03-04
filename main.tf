# Goal of this, is to redeploy the entire hospital environment automatically if an instance crashes or needs to be reset
# Hybrid Architecture (Containers + VMs) + VPC, Subnets, Security Groups, compute resources, etc.
# Full Disclosure, I used Google and Google Gemini to aid in the creation of this file, specially around CDIR Blocks and security

# TO DO LIST: 
# 3. No terraform.tfvars, or variable definitions, so the AMI IDs and region are hardcoded, a limitation to consider
# 4. Verify that us-east-1 is most appropriate region
# 5. Solution for how to deploy the docker-compose YAML within AWS would be to store the docker-compose file in an S3 bucket and have user_data pull it down with aws s3 cp. 


# ==========================================
# HOSPITAL HONEYPOT AUTOMATED DEPLOYMENT
# This script acts as a sort of blueprint, when run, AWS will automatically build 
# the entire hospital network, servers, and security rules, as defined
# Compliance: Strict outbound blocking to adhere to AWS Terms of Service 
# ==========================================



# This tells Terraform to build the infrastructure in the region us-east-1 (I thought it was most comvinient)
provider "aws" {
    region = "us-east-1"
}

# ==========================================
# STEP 1: NETWORK FOUNDATION
# Sort of like a property where we are building our hospital wing 
# ==========================================

# The VPC is our private "yard" within the AWS cloud "neighborhood"
resource "aws_vpc" "hospital_vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags = { Name = "Hospital-Honeypot-VPC" }
}

# The "Clinical Zone" is like a specific ward in the hospital for patients (legacy assets)
resource "aws_subnet" "clinical_zone" {
    vpc_id     = aws_vpc.hospital_vpc.id
    cidr_block = "10.0.1.0/24"
    tags       = { Name = "Clinical-Zone" }
}

# "The Brain" is the secure server room where all the data is collected and analyzed
resource "aws_subnet" "brain_zone" {
    vpc_id     = aws_vpc.hospital_vpc.id
    cidr_block = "10.0.2.0/24"
    tags       = { Name = "The-Brain-Zone" }
}

# ==========================================
# STEP 2: SECURITY GROUPS (Isolation/Digital Security Guards)
# These section will act as stateful firewalls, controlling who can talk to whom
# ==========================================

# Brain SG: Security rules for "The Brain" (Management Zone)
resource "aws_security_group" "brain_sg" {
    name   = "brain-sg"
    vpc_id = aws_vpc.hospital_vpc.id

    # Allow the clinical equipment to send their logs to the Brain for storage
    ingress {
        from_port   = 5044
        to_port     = 5044
        protocol    = "tcp"
        cidr_blocks = ["10.0.1.0/24"] # Allow Beats from Clinical Zone 
    }

    # Allow authorized staff to view the Kibana data dashboard via a secure VPN
    ingress {
        from_port   = 5601
        to_port     = 5601
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"] # Access via Client VPN 
    }

    # COMPLIANCE: "The Brain" is blocked from talking to the public internet
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["127.0.0.1/32"] # Block all outbound 
    }
}

# Clinical SG: Security rules for the "Clinical Zone" (Vulnerable Assets)
resource "aws_security_group" "clinical_sg" {
    name   = "clinical-sg"
    vpc_id = aws_vpc.hospital_vpc.id

    # Allow "The Brain" to check if these devices are still running ("Knocks")
    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["10.0.2.0/24"] # Allow Validation Script "Knocks" 
    }

    egress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["10.0.2.0/24"] # Allow log shipping to Brain 
    }

    # COMPLIANCE: These vulnerable devices are strictly forbidden from contacting the internet
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["127.0.0.1/32"] # Compliance: No Internet 
    }
}

# ==========================================
# STEP 3: COMPUTE RESOURCES (The Virtual Servers)
# These are the actual computers that will run our hospital software
# ==========================================

# The Brain (Ubuntu 22.04 + ELK Docker) 
# A powerful server used to run the ELK stack for data visualization
# t3.large is important due to resourse consuption of the ELK Stack surpasing what a t3.medium can provide
resource "aws_instance" "the_brain" {
    ami                    = "ami-0c7217cdde317cfec" 
    instance_type          = "t3.large"
    subnet_id              = aws_subnet.brain_zone.id
    vpc_security_group_ids = [aws_security_group.brain_sg.id]
    private_ip             = "10.0.2.10"
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

      # 3. Write Logstash Config (Note the unique delimiter)
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
resource "aws_instance" "win7_workstation" {
    ami                    = "ami-032599769356f916d" # AMI ID for Windows 2012 Server
    instance_type          = "t3.medium"
    subnet_id              = aws_subnet.clinical_zone.id
    vpc_security_group_ids = [aws_security_group.clinical_sg.id]
    tags                   = { Name = "Win7-Clinical-Workstation" }
}

# Imaging Server (Ubuntu + DICOM Sim) 
# Mimics a PACS system used to store X-rays and MRI scans
resource "aws_instance" "imaging_server" {
    ami                    = "ami-0c7217cdde317cfec"
    instance_type          = "t3.micro"
    subnet_id              = aws_subnet.clinical_zone.id
    vpc_security_group_ids = [aws_security_group.clinical_sg.id]
    private_ip             = "10.0.1.20"
    tags                   = { Name = "Imaging-Server-PACS" }
}

# IoT Gateway (Ubuntu + Conpot Docker)
# A specialized tool (Conpot) that pretends to be a medical device
resource "aws_instance" "iot_gateway" {
    ami                    = "ami-0c7217cdde317cfec"
    instance_type          = "t3.micro"
    subnet_id              = aws_subnet.clinical_zone.id
    vpc_security_group_ids = [aws_security_group.clinical_sg.id]
    private_ip             = "10.0.1.30"
    tags                   = { Name = "IoT-Gateway-Conpot" }
}

# ==========================================
# STEP 4: PRIVATE DNS (Route 53/Internal Phonebook) 
# This allows our servers to talk to each other using names instead of numbers
# ==========================================

# Creates a private directory called "hospital.internal" only visible inside this VPC
resource "aws_route53_zone" "private" {
    name = "hospital.internal"
    vpc { vpc_id = aws_vpc.hospital_vpc.id }
}

# Assigns the name "pacs.hospital.internal" to our Imaging Server's address
resource "aws_route53_record" "pacs" {
    zone_id = aws_route53_zone.private.zone_id
    name    = "pacs.hospital.internal"
    type    = "A"
    ttl     = "300"
    records = ["10.0.1.20"]
}

# Assigns the name "medical-workstation.hospital.internal" to the Windows Instance
resource "aws_route53_record" "medical_workstation" {
    zone_id = aws_route53_zone.private.zone_id
    name    = "medical-workstation.hospital.internal"
    type    = "A"
    ttl     = "300"
    records = [aws_instance.win7_workstation.private_ip]
}

# Assigns the name "iot-gateway.hospital.internal" to our IoT device.
resource "aws_route53_record" "iot" {
    zone_id = aws_route53_zone.private.zone_id
    name    = "iot-gateway.hospital.internal"
    type    = "A"
    ttl     = "300"
    records = ["10.0.1.30"]
}