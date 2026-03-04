# Goal of this, is to redeploy the entire hospital environment automatically if an instance crashes or needs to be reset
# Hybrid Architecture (Containers + VMs) + VPC, Subnets, Security Groups, compute resources, etc.
# Full Disclosure, I used Google and Google Gemini to aid in the creation of this file, specially around CDIR Blocks and security

# TO DO LIST: 
# 2. Need user_data, right now the script is only spining up blank Ubuntu instances, nothing install Docker or the other things
# 3. No terraform.tfvars, or variable definitions, so the AMI IDs and region are hardcoded, a limitation to consider
# 4. Verify that us-east-1 is most appropriate region

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

# Assigns the name "iot-gateway.hospital.internal" to our IoT device.
resource "aws_route53_record" "iot" {
    zone_id = aws_route53_zone.private.zone_id
    name    = "iot-gateway.hospital.internal"
    type    = "A"
    ttl     = "300"
    records = ["10.0.1.30"]
}