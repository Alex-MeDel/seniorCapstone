# ==========================================
# STEP 2: SECURITY GROUPS (Isolation/Digital Security Guards)
# These section will act as stateful firewalls, controlling who can talk to whom
# ==========================================

# Google Gemini AI helped with brainstorming and research for this section, it also helped with polishing the code a little (removing incessary parts and rewriting some parts to make it more clear and professional)

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

    # SSH ingress rule
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"] # Via VPN only
}

    # COMPLIANCE: "The Brain" is blocked from talking to the public internet
    #egress {
    #    from_port   = 0
    #    to_port     = 0
    #    protocol    = "-1"
    #    cidr_blocks = ["127.0.0.1/32"] # Block all outbound 
    #}

    # TEMPORARY CODE: Allow outbound internet for bootstrapping (Docker images, apt packages)
    # TODO: Restrict this after initial deployment is validated
    # Option 1. Edit the main.tf and re-apply, just swap to old, commented version of this egress
    # just a terraform apply after the edit should do it, according to the AI it will update the security group rule
    # without touching the already configured 
    # Option 2. Manutally, in the AWS Console EC2 -> Security Groups -> find brain-sg and clinical-sg -> edit
    # outbound rules -> delete the 0.0.0.0/0 rule. No terraform needed.
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
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

    # Allow log shipping to Brain over TCP (Filebeat/Winlogbeat → Logstash port 5044)
    egress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["10.0.2.0/24"] # Allow log shipping to Brain 
    }

    # New Addition
    # Allow DNS resolution via Route 53 (UDP port 53) — required for hospital.internal hostnames
    # Without this, internal DNS names like pacs.hospital.internal silently fail after bootstrap lockdown
    egress {
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_blocks = ["10.0.0.0/16"] # VPC-wide, I think
    }

    # COMPLIANCE: These vulnerable devices are strictly forbidden from contacting the internet
    #egress {
    #    from_port   = 0
    #    to_port     = 0
    #    protocol    = "-1"
    #    cidr_blocks = ["127.0.0.1/32"] # Compliance: No Internet 
    #}

    # TEMPORARY CODE: Allow outbound internet for bootstrapping (Filebeat, Winlogbeat, conpot, DCM4CHE)
    # TODO: Restrict this after initial deployment is validated
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
