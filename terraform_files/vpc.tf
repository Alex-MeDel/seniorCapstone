# ==========================================
# NETWORKING CORE: VPC, Subnets & Routing
# Description: Defines the network boundary, isolated subnets, 
# and route tables for the Hospital Honeypot architecture.
# ==========================================

# Foundational Virtual Private Cloud (VPC)
resource "aws_vpc" "hospital_vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    tags = { Name = "Hospital-Honeypot-VPC" }
}

# ------------------------------------------
# SUBNET 1: Clinical Zone (Vulnerable Assets)
# ------------------------------------------
# Private subnet that hauses the "honey" assets 
resource "aws_subnet" "clinical_zone" {
    vpc_id     = aws_vpc.hospital_vpc.id
    cidr_block = "10.0.1.0/24"
    tags       = { Name = "Clinical-Zone" }
}

# ------------------------------------------
# SUBNET 2: The Brain Zone (Management & Logging)
# ------------------------------------------
# Public-facing management subnet hosting the ELK stack
resource "aws_subnet" "brain_zone" {
    vpc_id     = aws_vpc.hospital_vpc.id
    cidr_block = "10.0.2.0/24"
    tags       = { Name = "The-Brain-Zone" }
}

# ==========================================
# INTERNET GATEWAY & ROUTING
# Description: Provides external routing for bootstrap package 
# retrieval and whitelisted administrator access.
# ==========================================

# Full Disclosure: Google Gemini AI helped me produce and understand this part of the code
# All code was tested and crossreferenced with documentation by me.
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.hospital_vpc.id
  tags   = { Name = "Hospital-Honeypot-IGW" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.hospital_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "Hospital-Public-RT" }
}

# Associate both subnets so instances can reach the internet during bootstrap
resource "aws_route_table_association" "brain_rta" {
  subnet_id      = aws_subnet.brain_zone.id
  route_table_id = aws_route_table.public_rt.id
}

# NOTE: In a strict zero-trust production environment, this association 
# would be removed post-bootstrap to make the Clinical Zone a true private subnet.
# Currently, isolation is enforced via Security Group egress/ingress rules.
resource "aws_route_table_association" "clinical_rta" {
  subnet_id      = aws_subnet.clinical_zone.id
  route_table_id = aws_route_table.public_rt.id
}