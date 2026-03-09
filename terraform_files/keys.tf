# ==========================================
# AUTHENTICATION: Cryptographic Key Pairs
# Description: Provisions the public SSH key required for secure, 
# passwordless access to the Linux-based EC2 instances.
# ==========================================

# PREREQUISITE: Generate the key pair locally before running 'terraform apply'
# Command: ssh-keygen -t rsa -b 4096 -f ~/.ssh/honeypot_key

# POST-DEPLOYMENT ACCESS:
# Command: ssh -i ~/.ssh/honeypot_key ubuntu@<brain_public_ip>

resource "aws_key_pair" "honeypot_key" {
    key_name   = "honeypot-key"
    public_key = file("~/.ssh/honeypot_key.pub")
}
