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
# STEP 1.5: INTERNET GATEWAY + ROUTING
# Gives the VPC an on-ramp to the internet for bootstrapping (Temporary, will later remove access)
# ==========================================

# Google Gemini AI helped me produce and understand this part of the code 
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

# REMOVE THIS AFTER DEPLOYMENT VALIDATION!!!!
resource "aws_route_table_association" "clinical_rta" {
  subnet_id      = aws_subnet.clinical_zone.id
  route_table_id = aws_route_table.public_rt.id
}