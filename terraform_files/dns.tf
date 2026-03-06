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
    records = [aws_instance.win_workstation.private_ip]
}

# Assigns the name "iot-gateway.hospital.internal" to our IoT device.
resource "aws_route53_record" "iot" {
    zone_id = aws_route53_zone.private.zone_id
    name    = "iot-gateway.hospital.internal"
    type    = "A"
    ttl     = "300"
    records = ["10.0.1.30"]
}