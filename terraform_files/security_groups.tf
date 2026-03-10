# ==========================================
# SECURITY GROUPS: Network Isolation & Access Control
# These section will act as stateful firewalls, controlling who can talk to whom
# ==========================================
# Architecture Traffic Flow:
# 1. Boostrap phase - initial setup requires internet access
# 2. Change the code according to comments after boostrapping
# 3. External access is strictly whitelisted to the authorized administrator IP or Client VPN after boostrap phase.
# 4. Attacker tries to talk to Honeypot (Clinical SG)
# 5. Honeypot sends logs of attack to The brain (Brain SG via Port 5044)
# 6. We log into The Brain to see the results (Brain SG via port 5601)

# Full Disclosure Google Gemini AI helped with brainstorming and research for this section, 
# it also helped with debugging and polish of the code and comments a little

# ------------------------------------------
# 1. "The Brain" Security Group (Management & Logging)
# ------------------------------------------
resource "aws_security_group" "brain_sg" {
    name   = "brain-sg"
    description = "Security rules for The Brain (Management Zone)"
    vpc_id = aws_vpc.hospital_vpc.id

    # INGRESS: Who to allow to connect via SSH
    ingress {
        from_port   = 22 # 22 is standard SSH port
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # <-- Bootstrapping code (Change to one of other options after boostrapping phase)
    #    cidr_blocks = ["10.0.0.0/16"] # Via Client VPN only
    #    cidr_blocks = ["IP_ADDRESS/32"] # Via IP whitelist only
    }

    # INGRESS: Who to allow to connect to Kibana
    ingress {
        from_port   = 5601 # Default port used by Kibana
        to_port     = 5601
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # <-- Bootstrapping code (Change to one of other options after boostrapping phase)
    #    cidr_blocks = ["10.0.0.0/16"] # Via Client VPN only
    #    cidr_blocks = ["IP_ADDRESS/32"] # Via IP whitelist only
    }

    # INGRESS: Allow the clinical equipment to send their logs to the Brain for storage
    ingress {
        from_port   = 5044 # 5044 Kibana dashboard port
        to_port     = 5044
        protocol    = "tcp"
        cidr_blocks = ["10.0.1.0/24"] # Allow Beats from Clinical Zone 
    }

    # EGRESS: "The Brain" is blocked from talking to the public internet
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"] # BOOTSTRAPPING - Comment out when finished boostrapping
    #    cidr_blocks = ["127.0.0.1/32"] # Block all outbound, uncomment after boostrapping
    }
}

# ------------------------------------------
# 2. "Clinical Zone" Security Group (Vulnerable Assets)
# ------------------------------------------
resource "aws_security_group" "clinical_sg" {
    name   = "clinical-sg"
    description = "Security rules for the Clinical Zone (Vulnerable Assets)"
    vpc_id = aws_vpc.hospital_vpc.id

    # INGRESS: Allow Validation Script "Knocks" from The Brain
    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["10.0.2.0/24"] # Allow Validation Script "Knocks" 
    }

    # TEMPORARY DEBUGGING: RDP ingress rule due to no response from Win Workstation after 30 mins
    #ingress {
    #    from_port   = 3389
    #    to_port     = 3389
    #    protocol    = "tcp"
    #    cidr_blocks = ["0.0.0.0/0"]
    #}

    # TEMPORARY DEBUGGING: SSH ingress rule for Clinical SG - DELETE OR COMMENT LATER!!!
    #ingress {
    #    from_port   = 22 
    #    to_port     = 22
    #    protocol    = "tcp"
    #    cidr_blocks = ["0.0.0.0/0"] # <-- Temporarily open to check logs
    #}

    # EGRESS: Allow log shipping to Brain over TCP (Filebeat/Winlogbeat → Logstash port 5601)
    egress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["10.0.2.0/24"] # Allow log shipping to Brain 
    }

    # EGRESS: Allow DNS resolution via Route 53 (UDP port 53)
    # Required for hospital.internal hostnames to resolve post-lockdown
    # This was a Claude AI recommendation
    egress {
        from_port   = 53
        to_port     = 53
        protocol    = "udp"
        cidr_blocks = ["10.0.0.0/16"] # VPC-wide, I think
    }


    # EGRESS: Compliance lockdown - Block all outbound internet traffic
    # Necessary to be open during boostrapping phase for downloads
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"] # Bootstrapping code 
    #    cidr_blocks = ["127.0.0.1/32"] # Compliance: No Internet 
    }
}
